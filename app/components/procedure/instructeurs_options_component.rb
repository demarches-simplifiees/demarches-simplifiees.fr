class Procedure::InstructeursOptionsComponent < ApplicationComponent
  def initialize(procedure:, state:)
    @procedure = procedure
    @state = state
  end
end
