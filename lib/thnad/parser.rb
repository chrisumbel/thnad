require 'parslet'

module Thnad
  class Parser < Parslet::Parser
    # gotta see it all
    rule(:space)  { match('\s').repeat(1) }
    rule(:space?) { space.maybe }

    # punctuation
    rule(:lparen) { str('(') >> space? }
    rule(:rparen) { str(')') >> space? }
    rule(:lbrace) { str('{') >> space? }
    rule(:rbrace) { str('}') >> space? }
    rule(:comma)  { str(',') >> space? }

    # keywords
    rule(:if_kw)   { str('if')       >> space? }
    rule(:else_kw) { str('else')     >> space  }
    rule(:func_kw) { str('function') >> space  }

    rule(:name) { match('[a-z]').repeat(1).as(:name) >> space? }
    rule(:variable) { name.as(:variable) }
    rule(:number) { match('[0-9]').repeat(1).as(:number) >> space? }

    # parameters listed in a function definition
    rule(:params) {
      lparen >>
        ((name.as(:param) >> (comma >> name.as(:param)).repeat(0)).maybe).as(:params) >>
      rparen
    }

    # arguments passed in a function call
    rule(:args) {
      lparen >>
        ((expression.as(:arg) >> (comma >> expression.as(:arg)).repeat(0)).maybe).as(:args) >>
      rparen
    }

    rule(:funcall) { name.as(:funcall) >> args }

    rule(:cond) {
      if_kw >> lparen >> expression.as(:cond) >> rparen >>
        body.as(:if_true) >>
        else_kw >>
        body.as(:if_false)
    }

    rule(:expression) { cond | funcall | variable | number }

    rule(:body) { lbrace >> expression.repeat(0).as(:body) >> rbrace }

    rule(:func) {
      func_kw >> name.as(:func) >> params >> body
    }

    rule(:program) { func.repeat(0) >> expression.repeat(1) }

    root(:program)
  end
end
