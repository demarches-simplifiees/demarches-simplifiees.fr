# frozen_string_literal: true

class Instructeurs::WarningBannerComponent < ApplicationComponent
  def initialize(draft:, single_procedure:)
    @draft = draft
    @single_procedure = single_procedure
  end

  def render? = @draft

  private

  attr_reader :draft, :single_procedure
end
