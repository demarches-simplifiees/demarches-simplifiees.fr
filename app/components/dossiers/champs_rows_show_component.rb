# frozen_string_literal: true

class Dossiers::ChampsRowsShowComponent < ApplicationComponent
  attr_reader :profile
  attr_reader :seen_at

  def initialize(champs:, profile:, seen_at:)
    @champs, @profile, @seen_at = champs, profile, seen_at
  end

  private

  def updated_at_after_deposer(champ)
    return if champ.dossier.depose_at.blank?
    return if champ.new_record?

    if champ.updated_at > champ.dossier.depose_at
      champ.updated_at
    end
  end

  def number_with_html_delimiter(num)
    # we are using the span delimiter that doesn't insert spaces when copying and pasting the number
    number_with_delimiter(num, delimiter: tag.span(class: 'numbers-delimiter'))
  end

  def blank_key(champ)
    key = champ.mandatory? ? ".blank" : ".blank_optional"
    key += "_attachment" if champ.piece_justificative_or_titre_identite?

    key
  end

  def visible?(champ)
    return false if champ.header_section? || champ.explication?
    return true if champ.visible?

    if profile == 'instructeur' && champ.public?
      champ.submitted_filled?
    else
      false
    end
  end

  def each_champ(&block)
    @champs.filter { visible?(_1) }.each(&block)
  end
end
