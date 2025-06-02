# frozen_string_literal: true

class Dossiers::UserProcedureFilterComponent < ApplicationComponent
  include DossierHelper

  def initialize(procedures_for_select:)
    @procedures_for_select = procedures_for_select
  end
end
