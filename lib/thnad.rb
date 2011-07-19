require 'parslet'

module Thnad
  class Parser < Parslet::Parser
    rule(:space) { match('\s').repeat(1) } # gotta see it all
    rule(:space?) { space.maybe }

    rule(:lparen) { str('(') >> space? }
    rule(:rparen) { str(')') >> space?}

    rule(:lbrace) { str('{') >> space? }
    rule(:rbrace) { str('}') >> space? }

    rule(:comma) { str(',') >> space? }

    rule(:name) { match('[a-z]').repeat(1) >> space? }
    rule(:number) { match('[0-9]').repeat(1) >> space? }

    rule(:operand) { name | number }
    rule(:operator) { match('[++/-]') }
    rule(:calculation) { operand.as(:left) >> operator.as(:op) >> operand.as(:right) }

    rule(:expression) { calculation }

    rule(:params) {
      lparen >>
        ((name.as(:name) >> (comma >> name.as(:name)).repeat(0)).maybe).as(:params) >>
      rparen
    }

    rule(:body) { lbrace >> calculation.repeat(0).as(:body) >> rbrace }

    rule(:func) {
      str('function') >> space >> name.as(:func) >> params >> body
    }

    root(:func)
  end

  class Function < Struct.new(:name, :params, :body)
  end

  class Transform < Parslet::Transform
    rule(:name => simple(:name)) { name }

    rule(:func   => simple(:func),
         :params => simple(:name),
         :body   => sequence(:body)) { Function.new(func, name, body) }

    rule(:func   => simple(:func),
         :params => sequence(:params),
         :body   => sequence(:body)) { Function.new(func, params, body) }
  end
end
