# frozen_string_literal: true

class EditableChamp::EtablissementTitreComponent < ApplicationComponent
  include EtablissementHelper

  def initialize(etablissement:)
    @etablissement = etablissement
  end
end
