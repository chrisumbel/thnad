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
    rule(:number) { match('[0-9]').repeat(1).as(:number) >> space? }

    rule(:operand) { name | number }
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

    def eval
      types = ['int'] * (params.count + 1)
      b.public_static_method(name, [], *types) do
        body.each(&:eval)
        b.ireturn
      end
    end
  end

  class Number < Struct.new(:value)
    include Emitter

    def eval
      b.ldc value
    end
  end

  class Transform < Parslet::Transform
    rule(:name => simple(:name)) { name }

    rule(:number => simple(:value)) { Number.new(value.to_i) }

    rule(:func   => simple(:func),
         :params => simple(:name),
         :body   => sequence(:body)) { Function.new(func, name, body) }

    rule(:func   => simple(:func),
         :params => sequence(:params),
         :body   => sequence(:body)) { Function.new(func, params, body) }
  end
end
