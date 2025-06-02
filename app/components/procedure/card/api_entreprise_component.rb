# frozen_string_literal: true

class Procedure::Card::APIEntrepriseComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
