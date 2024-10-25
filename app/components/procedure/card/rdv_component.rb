# frozen_string_literal: true

class Procedure::Card::RdvComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
