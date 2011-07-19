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
              :body   => [] }
    expected = Thnad::Function.new 'foo', ['x', 'y'], []
    @transform.apply(input).must_equal expected
  end
end
