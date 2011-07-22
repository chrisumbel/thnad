require 'minitest/autorun'
require 'minitest/spec'
require 'mocha'

$: << File.dirname(__FILE__) + '/../lib'
require 'thnad'

describe 'Emit' do
  before do
    @builder = mock
    @method  = mock
    Thnad::Emitter.builder = @builder
    @context = Hash.new
  end

  it 'emits a function def with two args' do
    input = Thnad::Function.new 'foo', ['x', 'y'], [Thnad::Number.new(5)]

    @builder.expects(:int).returns('int')
    @builder.expects(:public_static_method).with('foo', [], 'int', 'int', 'int').yields(@method)
    @method.expects(:ldc).with(5)
    @method.expects(:ireturn)

    input.eval @context
  end

  it 'emits a function def using a param' do
    input = Thnad::Function.new 'foo', 'x', [Thnad::Local.new('x')]

    @builder.expects(:int).returns('int')
    @builder.expects(:public_static_method).with('foo', [], 'int', 'int').yields(@method)
    @method.expects(:iload).with(0)
    @method.expects(:ireturn)

    input.eval @context
  end

  it 'emits a function call' do
    input = Thnad::Funcall.new 'print', [Thnad::Number.new(42)]
    @context['_int'] = 'int'
    @context['_class'] = 'example'

    @builder.expects(:ldc).with(42)
    @builder.expects(:invokestatic).with('example', 'print', ['int', 'int'])

    input.eval @context
  end
end
