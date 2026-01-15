# frozen_string_literal: true

class NestedForms::OwnedButtonComponent < ApplicationComponent
  renders_one :button_label

  def initialize(formaction:, http_method:, opt: {})
    @formaction = formaction
    @http_method = http_method
    @opt = opt
  end

  def call
    merged_data = (@opt[:data] || {}).merge(turbo: 'true')
    button_tag(content, @opt.merge(formaction: @formaction, form: NestedForms::FormOwnerComponent.form_id(@http_method), data: merged_data))
  end
end
