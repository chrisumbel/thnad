require 'bitescript'

module Thnad
  class Compiler
    def compile(filename)
      source      = File.expand_path(filename)
      klass       = File.basename(filename, '.thnad')
      destination = File.expand_path(klass + '.class')

      parser      = Thnad::Parser.new
      transform   = Thnad::Transform.new

      program   = IO.read source
      syntax    = parser.parse(program)
      tree      = transform.apply(syntax)

      builder = BiteScript::FileBuilder.build(filename) do
        public_class klass, object do |c|
          first_expr = tree.index { |t| ! t.is_a?(Function) }
          funcs = tree[0...first_expr]
          exprs = tree[first_expr..-1]

          Thnad::Emitter.builder = c
          funcs.each do |f|
            context = Hash.new
            context['_class'] = c
            f.eval(context)
          end

          c.public_static_method 'main', [], void, string[] do |b|
            Thnad::Emitter.builder = b
            exprs.each do |t|
              context = Hash.new
              context['_int'] = c.int
              context['_class'] = c

              t.eval(context)
            end
            b.returnvoid
          end

          c.public_static_method 'print', [], int, int do
            iload 0
            println(int)
            ldc 0
            ireturn
          end
        end
      end

      builder.generate do |n, b|
        File.open(destination, 'wb') do |f|
          f.write b.generate
        end
      end

    end
  end
end
