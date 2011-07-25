require 'minitest/autorun'
require 'minitest/spec'
require 'mocha'

$: << File.dirname(__FILE__) + '/../lib'
require 'thnad'

describe 'Emit' do
  before do
    @builder = mock
    @class   = mock
    @context = Hash.new
  end

  it 'emits a function def with two args' do
    input = Thnad::Function.new 'foo', ['x', 'y'], [Thnad::Number.new(5)]

    @builder.expects(:int).returns('int')
    @builder.expects(:public_static_method).with('foo', [], 'int', 'int', 'int').yields(@method)
    @method.expects(:ldc).with(5)
    @method.expects(:ireturn)

    input.eval @context, @builder
  end

  it 'emits a function def using a param' do
    input = Thnad::Function.new 'foo', 'x', [Thnad::Local.new('x')]

    @builder.expects(:int).returns('int')
    @builder.expects(:public_static_method).with('foo', [], 'int', 'int').yields(@method)
    @method.expects(:iload).with(0)
    @method.expects(:ireturn)

    input.eval @context, @builder
  end

  it 'emits a function call' do
    input = Thnad::Funcall.new 'print', [Thnad::Number.new(42)]

    @builder.expects('class_builder').returns(@class)
    @builder.expects(:int).returns('int')
    @builder.expects(:ldc).with(42)
    @builder.expects(:invokestatic).with(@class, 'print', ['int', 'int'])

    input.eval @context, @builder
  end

  it 'emits a conditional' do
    input = Thnad::Conditional.new \
      Thnad::Number.new(0),
      [Thnad::Number.new(42)],
      [Thnad::Number.new(667)]

    @builder.expects(:ldc).with(0)
    @builder.expects(:ifeq).with(:else)
    @builder.expects(:ldc).with(42)
    @builder.expects(:goto).with(:endif)
    @builder.expects(:label).with(:else)
    @builder.expects(:ldc).with(667)
    @builder.expects(:label).with(:endif)

    input.eval @context, @builder
  end
end
