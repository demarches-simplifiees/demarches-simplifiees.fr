# frozen_string_literal: true

require "administrate/field/base"

class ProcedureStateField < Administrate::Field::String
  def name
    "Statut"
  end
end
