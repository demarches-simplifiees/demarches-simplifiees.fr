# frozen_string_literal: true

class Procedure::Card::LabelsComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
