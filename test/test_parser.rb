require 'minitest/autorun'
require 'minitest/spec'

$: << File.dirname(__FILE__) + '/../lib'
require 'thnad'

describe Thnad::Parser do
  before do
    @parser = Thnad::Parser.new
  end

  it 'reads a no-arg function definition' do
    expected = { :func => 'foo', :params => nil, :body => [] }
    @parser.parse(<<HERE.strip).must_equal expected
function foo() {
}
HERE
  end

  it 'reads a function definition' do
    expected = { :func   => 'foo',
                 :params => { :name => 'x' },
                 :body   => [] }
    @parser.parse(<<HERE.strip).must_equal expected
function foo(x) {
}
HERE
  end
end
