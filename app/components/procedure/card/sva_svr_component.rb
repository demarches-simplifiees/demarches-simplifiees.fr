# frozen_string_literal: true

class Procedure::Card::SVASVRComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
