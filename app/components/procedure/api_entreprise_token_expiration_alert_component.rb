# frozen_string_literal: true

class Procedure::APIEntrepriseTokenExpirationAlertComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def render?
    @procedure.api_entreprise_token.expired_or_expires_soon?
  end

  private

  attr_reader :procedure
end
