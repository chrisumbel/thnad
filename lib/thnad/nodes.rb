require 'parslet'

module Thnad
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

  class Usage < Struct.new(:name)
    def eval(context, b)
      raise "Unknown name #{name}" unless (context[:params] || {}).include?(name)
      b.iload context[:params].index(name) # + 1
    end
  end
end
