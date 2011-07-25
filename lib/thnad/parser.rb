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

    rule(:name) { match('[a-z]').repeat(1).as(:name) >> space? }
    rule(:variable) { name.as(:variable) }
    rule(:number) { match('[0-9]').repeat(1).as(:number) >> space? }

    rule(:operand) { variable | number }
    rule(:operator) { match('[=*/+-]').as(:op) >> space? }
    rule(:calculation) { operand.as(:left) >> operator >> expression.as(:right) }

    rule(:params) {
      lparen >>
        ((name.as(:param) >> (comma >> name.as(:param)).repeat(0)).maybe).as(:params) >>
      rparen
    }

    rule(:args) {
      lparen >>
        ((expression.as(:arg) >> (comma >> expression.as(:arg)).repeat(0)).maybe).as(:args) >>
      rparen
    }

    rule(:funcall) { name.as(:funcall) >> args }

    rule(:cond) {
      str('if') >> lparen >> expression.as(:cond) >> rparen >>
      body.as(:if_true) >> str('else') >> space >> body.as(:if_false)
    }

    rule(:expression) { cond | funcall | calculation | operand }

    rule(:body) { lbrace >> expression.repeat(0).as(:body) >> rbrace }

    rule(:func) {
      str('function') >> space >> name.as(:func) >> params >> body
    }

    rule(:program) { func.repeat(0) >> expression.repeat(0) }

    root(:program)
  end
end
