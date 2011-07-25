module Thnad
  class Transform < Parslet::Transform
    rule(:name => simple(:name)) { name.to_s }

    rule(:number => simple(:value)) { Number.new(value.to_i) }

    rule(:usage => simple(:usage)) { Usage.new(usage) }

    rule(:arg => simple(:arg)) { arg }

    rule(:param => simple(:param)) { param }

    rule(:func   => simple(:func),
         :params => simple(:name),
         :body   => sequence(:body)) { Function.new(func.to_s, name, body) }

    rule(:func   => simple(:func),
         :params => sequence(:params),
         :body   => sequence(:body)) { Function.new(func.to_s, params, body) }

    rule(:funcall => simple(:funcall),
         :args    => simple(:number)) { Funcall.new(funcall.to_s, [number]) }

    rule(:funcall => simple(:funcall),
         :args    => sequence(:args)) { Funcall.new(funcall.to_s, args) }

    rule(:cond     => simple(:cond),
         :if_true  => {:body => sequence(:if_true)},
         :if_false => {:body => sequence(:if_false)}) { Conditional.new(cond, if_true, if_false) }
  end
end
