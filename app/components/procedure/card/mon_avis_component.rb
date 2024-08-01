# frozen_string_literal: true

class Procedure::Card::MonAvisComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
