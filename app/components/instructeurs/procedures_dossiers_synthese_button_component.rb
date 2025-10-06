# frozen_string_literal: true

class Instructeurs::ProceduresDossiersSyntheseButtonComponent < ApplicationComponent
  def initialize(procedures:)
    @procedures = procedures
  end

  def render? = @procedures.many?
end
