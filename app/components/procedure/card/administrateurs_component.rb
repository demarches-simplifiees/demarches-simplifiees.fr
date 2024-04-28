# frozen_string_literal: true

class Procedure::Card::AdministrateursComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
