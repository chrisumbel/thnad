require 'parslet'

module Thnad
  class Parser < Parslet::Parser
    rule(:space) { match('\s').repeat(1) } # gotta see it all
    rule(:space?) { space.maybe }

    rule(:lparen) { str('(') >> space? }
    rule(:rparen) { str(')') >> space?}

    rule(:lbrace) { str('{') >> space? }
    rule(:rbrace) { str('}') >> space? }

    rule(:comma) { str(',') >> space? }

    rule(:name) { match('[a-z]').repeat(1).as(:name) >> space? }
    rule(:variable) { name.as(:variable) }
    rule(:number) { match('[0-9]').repeat(1).as(:number) >> space? }

    rule(:operand) { variable | number }
    rule(:operator) { match('[++/-]') }
    rule(:calculation) { operand.as(:left) >> operator.as(:op) >> operand.as(:right) }

    rule(:expression) { calculation | operand }

    rule(:params) {
      lparen >>
        ((name.as(:param) >> (comma >> name.as(:param)).repeat(0)).maybe).as(:params) >>
      rparen
    }

    rule(:body) { lbrace >> expression.repeat(0).as(:body) >> rbrace }

    rule(:func) {
      str('function') >> space >> name.as(:func) >> params >> body
    }

    root(:func)
  end

  module Emitter
    def self.builder=(b)
      @@builder = b
    end

    private

    def b
      @@builder
    end
  end

  class Function < Struct.new(:name, :params, :body)
    include Emitter

    def eval(context)
      param_list = params.is_a?(Array) ? params : [params]

      context[:params] = param_list

      types = ['int'] * (param_list.count + 1)
      b.public_static_method(name, [], *types) do
        body.each { |e| e.eval(context) }
        b.ireturn
      end
    end
  end

  class Number < Struct.new(:value)
    include Emitter

    def eval(context)
      b.ldc value
    end
  end

  class Local < Struct.new(:name)
    include Emitter

    def eval(context)
      raise "Unknown variable #{name}" unless context[:params].include?(name)
      b.iload context[:params].index(name) + 1
    end
  end

  class Transform < Parslet::Transform
    rule(:name => simple(:name)) { name }

    rule(:number => simple(:value)) { Number.new(value.to_i) }

    rule(:variable => simple(:variable)) { Local.new(variable) }

    rule(:func   => simple(:func),
         :params => simple(:name),
         :body   => sequence(:body)) { Function.new(func, name, body) }

    rule(:func   => simple(:func),
         :params => sequence(:params),
         :body   => sequence(:body)) { Function.new(func, params, body) }
  end
end
