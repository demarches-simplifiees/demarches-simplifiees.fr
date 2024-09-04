# frozen_string_literal: true

# context: https://github.com/demarches-simplifiees/demarches-simplifiees.fr/issues/8661
#   a11y: a post/delete/patch/put action must be wrapped in a <button>, not in an <a>
#   but we can't nest <forms>
#   this component exposes each http methods within a form, and can be used with OwnedButtonComponent
# background: https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button#attributes
#   see: from attribute & formaction

class NestedForms::FormOwnerComponent < ApplicationComponent
  HTTP_METHODS = [:create, :delete]

  private

  def self.form_id(http_method)
    raise ArgumentError, "invalid http_method: #{http_method}. supported methods are: #{HTTP_METHOD.join(',')}" if !HTTP_METHODS.include?(http_method)
    "unested-form-#{http_method}"
  end
end
