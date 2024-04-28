# frozen_string_literal: true

class Procedure::Card::ChorusComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def render?
    @procedure.chorusable?
  end

  def complete?
    @procedure.chorus_configuration.complete?
  end
end
