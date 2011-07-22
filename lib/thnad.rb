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

    rule(:params) {
      lparen >>
        ((name.as(:param) >> (comma >> name.as(:param)).repeat(0)).maybe).as(:params) >>
      rparen
    }

    rule(:args) {
      lparen >>
        ((operand.as(:arg) >> (comma >> operand.as(:arg)).repeat(0)).maybe).as(:args) >>
      rparen
    }

    rule(:funcall) { name.as(:funcall) >> args }

    rule(:expression) { funcall | calculation | operand }

    rule(:body) { lbrace >> expression.repeat(0).as(:body) >> rbrace }

    rule(:func) {
      str('function') >> space >> name.as(:func) >> params >> body
    }

    rule(:program) { func.repeat(0) >> expression.repeat(0) }

    root(:program)
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

      _name = name
      _body = body

      types = [b.int] * (param_list.count + 1)
      b.public_static_method(_name, [], *types) do |m|
        ::Thnad::Emitter.builder = m
        _body.each { |e| e.eval(context) }
        b.ireturn
      end
    end
  end

  class Funcall < Struct.new(:name, :args)
    include Emitter

    def eval(context)
      args.each { |a| a.eval(context) }
      types = [context['_int']] * (args.length + 1)
      b.invokestatic context['_class'], name, types
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
      b.iload context[:params].index(name) # + 1
    end
  end

  class Transform < Parslet::Transform
    rule(:name => simple(:name)) { name.to_s }

    rule(:number => simple(:value)) { Number.new(value.to_i) }

    rule(:variable => simple(:variable)) { Local.new(variable) }

    rule(:arg => simple(:arg)) { arg }

    rule(:param => simple(:param)) { param }

    rule(:func   => simple(:func),
         :params => simple(:name),
         :body   => sequence(:body)) { Function.new(func.to_s, name, body) }

    rule(:func   => simple(:func),
         :params => sequence(:params),
         :body   => sequence(:body)) { Function.new(func.to_s, params, body) }

    rule(:funcall => simple(:funcall),
         :args    => simple(:number)) { Funcall.new(funcall.to_s, [number]) }

    rule(:funcall => simple(:funcall),
         :args    => sequence(:args)) { Funcall.new(funcall.to_s, args, body) }
  end
end
