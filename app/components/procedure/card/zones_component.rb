# frozen_string_literal: true

class Procedure::Card::ZonesComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
