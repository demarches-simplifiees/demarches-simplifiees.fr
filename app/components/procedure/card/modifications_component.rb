# frozen_string_literal: true

class Procedure::Card::ModificationsComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def render?
    @procedure.revised?
  end
end
