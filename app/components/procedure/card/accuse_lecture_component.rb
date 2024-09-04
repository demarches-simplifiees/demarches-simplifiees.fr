# frozen_string_literal: true

class Procedure::Card::AccuseLectureComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
