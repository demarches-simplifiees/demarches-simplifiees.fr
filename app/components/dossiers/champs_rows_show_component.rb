class Dossiers::ChampsRowsShowComponent < ApplicationComponent
  attr_reader :profile
  attr_reader :seen_at

  def initialize(champs:, profile:, seen_at:)
    @champs = champs
    @seen_at = seen_at
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
    key = ".blank_optional"
    key += "_attachment" if champ.type_de_champ.piece_justificative?

    key
  end

  def each_champ(&block)
    @champs.filter { _1.visible? && !_1.exclude_from_view? && !_1.header_section? }.each(&block)
  end
end
