require 'minitest/autorun'
require 'minitest/spec'
require 'mocha'

$: << File.dirname(__FILE__) + '/../lib'
require 'thnad'

describe 'Emit' do
  before do
    @builder = mock
    Thnad::Emitter.builder = @builder
    @context = Hash.new
  end

  it 'emits a function def with two args' do
    input = Thnad::Function.new 'foo', ['x', 'y'], [Thnad::Number.new(5)]

    @builder.expects(:public_static_method).with('foo', [], 'int', 'int', 'int').yields
    @builder.expects(:ldc).with(5)
    @builder.expects(:ireturn)

    input.eval @context
  end

  it 'emits a function def using a param' do
    input = Thnad::Function.new 'foo', 'x', [Thnad::Local.new('x')]

    @builder.expects(:public_static_method).with('foo', [], 'int', 'int').yields
    @builder.expects(:iload).with(1)
    @builder.expects(:ireturn)

    input.eval @context
  end
end
