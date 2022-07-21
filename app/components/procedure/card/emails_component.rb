class Procedure::Card::EmailsComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end
end
