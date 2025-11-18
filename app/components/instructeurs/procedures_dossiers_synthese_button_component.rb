# frozen_string_literal: true

class Instructeurs::ProceduresDossiersSyntheseButtonComponent < ApplicationComponent
  def initialize(procedures_count:)
    @procedures_count = procedures_count
  end

  def render? = @procedures_count > 1
end
