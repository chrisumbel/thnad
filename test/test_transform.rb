require 'minitest/autorun'
require 'minitest/spec'

$: << File.dirname(__FILE__) + '/../lib'
require 'thnad'

describe Thnad::Transform do
  before do
    @transform = Thnad::Transform.new
  end

  it 'transforms a function def with one arg' do
    input = { :func   => 'foo',
              :params => { :name => 'x' },
              :body   => [] }
    expected = Thnad::Function.new 'foo', 'x', []
    @transform.apply(input).must_equal expected
  end

  it 'transforms a function def with two args' do
    input = { :func   => 'foo',
              :params => [ { :name => 'x' },
                           { :name => 'y' } ],
              :body   => [ { :number => '5' } ] }
    expected = Thnad::Function.new 'foo', ['x', 'y'], [Thnad::Number.new(5)]
    @transform.apply(input).must_equal expected
  end

  it 'transforms a variable inside a function' do
    input = { :func   => { :name => 'foo' },
              :params => { :name => 'x' },
              :body   => [ { :variable => { :name => 'x' } } ] }
    expected = Thnad::Function.new 'foo', 'x', [Thnad::Local.new('x')]
    @transform.apply(input).must_equal expected
  end

  it 'transforms a function call' do
    input = { :funcall => { :name => 'foo' },
              :args    => { :arg => { :number => '42' } } }
    expected = Thnad::Funcall.new 'foo', [Thnad::Number.new(42)]
    @transform.apply(input).must_equal expected
  end
end
