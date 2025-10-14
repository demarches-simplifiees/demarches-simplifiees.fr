# frozen_string_literal: true

class Procedure::Card::APITokenComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
