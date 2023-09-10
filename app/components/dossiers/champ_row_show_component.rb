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

  def each_champ(&block)
    @champs.filter { show_champ?(_1) && _1.visible? && !_1.exclude_from_view? }.each(&block)
  end

  private

  # champ.blank? is overloaded, disable the cop
  # rubocop:disable Rails/Present
  def show_champ?(champ)
    if view_usager?
      true
    elsif champ.blank? && updated_after_deposer?(champ)
      true
    else
      !champ.blank?
    end
  end
  # rubocop:enable Rails/Present

  def view_usager?
    @profile == 'usager'
  end

  def view_instructeur?
    @profile == 'instructeur'
  end
end
