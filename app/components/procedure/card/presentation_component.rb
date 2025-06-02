# frozen_string_literal: true

class Procedure::Card::PresentationComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
