require 'minitest/autorun'
require 'minitest/spec'

$: << File.dirname(__FILE__) + '/../lib'
require 'thnad'

describe Thnad::Parser do
  before do
    @parser = Thnad::Parser.new
  end

  it 'reads a no-arg function definition' do
    expected = { :func   => { :name => 'foo' },
                 :params => nil,
                 :body   => [] }
    @parser.func.parse(<<HERE.strip).must_equal expected
function foo() {
}
HERE
  end

  it 'reads a function definition' do
    expected = { :func   => { :name => 'foo' },
                 :params => { :param => { :name => 'x' } },
                 :body   => [ { :number => '5' } ] }
    @parser.func.parse(<<HERE.strip).must_equal expected
function foo(x) {
    5
}
HERE
  end

  it 'reads a variable inside a function' do
    expected = { :func   => { :name => 'foo' },
                 :params => { :param => { :name => 'x' } },
                 :body   => [ { :variable => { :name => 'x' } } ] }
    @parser.func.parse(<<HERE.strip).must_equal expected
function foo(x) {
    x
}
HERE
  end

  it 'reads a function call' do
    expected = { :funcall => { :name => 'foo' },
                 :args    => { :arg => { :number => '42' } } }
    @parser.funcall.parse(<<HERE.strip).must_equal expected
foo(42)
HERE
  end

  it 'reads a nested function call' do
    expected = { :funcall => { :name => 'f' },
                 :args => { :arg => { :funcall => { :name => 'g' },
                                      :args => { :arg => { :number => '1' } } } } }
    @parser.funcall.parse(<<HERE.strip).must_equal expected
f(g(1))
HERE
  end

  it 'reads a conditional' do
    expected = { :cond     => { :number => '0' },
                 :if_true  => { :body => [ { :number => '42' } ] },
                 :if_false => { :body => [ { :number => '667' } ] } }
    @parser.cond.parse(<<HERE.strip).must_equal expected
if(0) {
  42
} else {
  667
}
HERE
  end
end
