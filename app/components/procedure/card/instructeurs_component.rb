# frozen_string_literal: true

class Procedure::Card::InstructeursComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
