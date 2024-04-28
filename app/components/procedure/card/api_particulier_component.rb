# frozen_string_literal: true

class Procedure::Card::APIParticulierComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  private

  def render?
    helpers.feature_enabled?(:api_particulier)
  end
end
