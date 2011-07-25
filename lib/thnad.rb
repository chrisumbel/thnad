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
    rule(:operator) { match('[=*/+-]').as(:op) >> space? }
    rule(:calculation) { operand.as(:left) >> operator >> expression.as(:right) }

    rule(:params) {
      lparen >>
        ((name.as(:param) >> (comma >> name.as(:param)).repeat(0)).maybe).as(:params) >>
      rparen
    }

    rule(:args) {
      lparen >>
        ((expression.as(:arg) >> (comma >> expression.as(:arg)).repeat(0)).maybe).as(:args) >>
      rparen
    }

    rule(:funcall) { name.as(:funcall) >> args }

    rule(:cond) {
      str('if') >> lparen >> expression.as(:cond) >> rparen >>
      body.as(:if_true) >> str('else') >> space >> body.as(:if_false)
    }

    rule(:expression) { cond | funcall | calculation | operand }

    rule(:body) { lbrace >> expression.repeat(0).as(:body) >> rbrace }

    rule(:func) {
      str('function') >> space >> name.as(:func) >> params >> body
    }

    rule(:program) { func.repeat(0) >> expression.repeat(0) }

    root(:program)
  end

  class Calculation < Struct.new(:left, :op, :right)
    def eval(context, b)
      left.eval context, b
      right.eval context, b
      case op
      when '+' then b.iadd
      when '-' then b.isub
      when '*' then b.imul
      when '/' then b.idiv
      when '=' then
        b.if_icmpeq :eq
        b.ldc 0
        b.goto :endeq
        b.label :eq
        b.ldc -1
        b.label :endeq
      else
        raise "Unknown operator #{op}"
      end
    end
  end

  class Function < Struct.new(:name, :params, :body)
    def eval(context, b)
      param_list = params.is_a?(Array) ? params : [params]

      context[:params] = param_list

      types = [b.int] * (param_list.count + 1)
      b.public_static_method(self.name, [], *types) do |m|
        self.body.each do |e|
          e.eval(context, m)
        end
        m.ireturn
      end
    end
  end

  class Funcall < Struct.new(:name, :args)
    def eval(context, b)
      args.each { |a| a.eval(context, b) }
      types = [b.int] * (args.length + 1)
      b.invokestatic b.class_builder, name, types
    end
  end

  class Conditional < Struct.new(:cond, :if_true, :if_false)
    def eval(context, b)
      cond.eval context, b
      b.ifeq :else
      if_true.each { |e| e.eval context, b }
      b.goto :endif
      b.label :else
      if_false.each { |e| e.eval context, b }
      b.label :endif
    end
  end

  class Number < Struct.new(:value)
    def eval(context, b)
      b.ldc value
    end
  end

  class Local < Struct.new(:name)
    def eval(context, b)
      raise "Unknown variable #{name}" unless (context[:params] || {}).include?(name)
      b.iload context[:params].index(name) # + 1
    end
  end

  class Transform < Parslet::Transform
    rule(:name => simple(:name)) { name.to_s }

    rule(:number => simple(:value)) { Number.new(value.to_i) }

    rule(:variable => simple(:variable)) { Local.new(variable) }

    rule(:arg => simple(:arg)) { arg }

    rule(:left  => simple(:left),
         :op    => simple(:op),
         :right => simple(:right)) { Calculation.new left, op, right }

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
         :args    => sequence(:args)) { Funcall.new(funcall.to_s, args) }

    rule(:cond     => simple(:cond),
         :if_true  => {:body => sequence(:if_true)},
         :if_false => {:body => sequence(:if_false)}) { Conditional.new(cond, if_true, if_false) }
  end
end
