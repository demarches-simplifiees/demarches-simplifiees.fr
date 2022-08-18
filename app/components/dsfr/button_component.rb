class Dsfr::ButtonComponent < ApplicationComponent
  private

  def initialize(label:, form: nil, url: nil, class_names: [])
    @form = form
    @label = label
    @url = url
    @class_names = Array(class_names)
  end

  attr_reader :form, :url, :label, :class_names
end
