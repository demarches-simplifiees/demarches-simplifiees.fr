class Dossiers::ChampRowShowComponent < ApplicationComponent
  include ChampHelper
  include DossierHelper
  include ApplicationHelper

  def initialize(champs:, demande_seen_at:, profile:, repetition:)
    @repetition = repetition
    @champs = champs
    @demande_seen_at = demande_seen_at
    @profile = profile
  end

  def updated_after_deposer?(champ)
    return false if champ.dossier.depose_at.blank?

    champ.updated_at > champ.dossier.depose_at
  end

  def number_with_html_delimiter(num)
    # we are using the span delimiter that doesn't insert spaces when copying and pasting the number
    number_with_delimiter(num, delimiter: tag.span(class: 'numbers-delimiter'))
  end

  def blank_key(champ)
    key = ".blank"
    key += "_optional" if @profile == "usager"
    key += "_attachment" if champ.type_de_champ.piece_justificative?

    key
  end
end
