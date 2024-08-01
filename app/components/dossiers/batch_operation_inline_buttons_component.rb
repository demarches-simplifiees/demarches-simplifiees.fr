# frozen_string_literal: true

class Dossiers::BatchOperationInlineButtonsComponent < ApplicationComponent
  attr_reader :opt, :icons, :form

  def initialize(opt:, icons:, form:)
    @opt = opt
    @icons = icons
    @form = form
  end
end
