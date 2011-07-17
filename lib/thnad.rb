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
    rule(:calculation) { operand >> operator >> operand }

    rule(:expression) { calculation }

    rule(:args) {
      lparen >>
        (name >> (comma >> name).repeat(0)).maybe >>
      rparen
    }

    rule(:body) { lbrace >> calculation.repeat(0) >> rbrace }

    rule(:func) {
      str('function') >> space >> name.as(:func) >> args >> body
    }

    root(:func)
  end
end
