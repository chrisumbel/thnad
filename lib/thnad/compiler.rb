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
          funcs = first_expr ? tree[0...first_expr] : tree
          exprs = first_expr ? tree[first_expr..-1] : []

          funcs.each do |f|
            context = Hash.new
            f.eval(context, c)
          end

          c.public_static_method 'main', [], void, string[] do |b|
            exprs.each do |t|
              context = Hash.new
              t.eval(context, b)
            end
            b.returnvoid
          end

          c.public_static_method 'print', [], int, int do
            iload 0
            println(int)
            ldc 0
            ireturn
          end

          c.public_static_method 'eq', [], int, int, int do
            iload 0
            iload 1
            if_icmpeq :eq
            ldc 0
            goto :endeq
            label :eq
            ldc 1
            label :endeq
            ireturn
          end

          c.public_static_method 'times', [], int, int, int do
            iload 0
            iload 1
            imul
            ireturn
          end

          c.public_static_method 'minus', [], int, int, int do
            iload 0
            iload 1
            isub
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
