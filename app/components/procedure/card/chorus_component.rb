class Procedure::Card::ChorusComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  def render?
    @procedure.chorusable?
  end

  def error_messages
    []
  end
end
