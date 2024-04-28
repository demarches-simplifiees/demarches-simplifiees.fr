# frozen_string_literal: true

class Dossiers::InvalidIneligibiliteRulesComponent < ApplicationComponent
  delegate :can_passer_en_construction?, to: :@dossier

  def initialize(dossier:)
    @dossier = dossier
    @revision = dossier.revision
  end

  def render?
    !can_passer_en_construction?
  end

  def error_message
    @dossier.revision.ineligibilite_message
  end
end
