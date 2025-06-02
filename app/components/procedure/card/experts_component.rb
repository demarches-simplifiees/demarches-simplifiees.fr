# frozen_string_literal: true

class Procedure::Card::ExpertsComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
