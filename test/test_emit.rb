require 'minitest/autorun'
require 'minitest/spec'
require 'mocha'

$: << File.dirname(__FILE__) + '/../lib'
require 'thnad'

describe 'Emit' do
  before do
    @builder = mock
    Thnad::Emitter.builder = @builder
  end

  it 'emits a function def with two args' do
    input = Thnad::Function.new 'foo', ['x', 'y'], [Thnad::Number.new(5)]

    @builder.expects(:public_static_method).with('foo', [], 'int', 'int', 'int').yields
    @builder.expects(:ldc).with(5)
    @builder.expects(:ireturn)

    input.eval
  end
end
