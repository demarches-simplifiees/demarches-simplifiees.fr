class Champs::BooleanChamp < Champ
  TRUE_VALUE = 'true'
  FALSE_VALUE = 'false'

  before_validation :set_value_to_nil, if: -> { value.blank? }
  before_validation :set_value_to_false, unless: -> { ([nil, TRUE_VALUE, FALSE_VALUE]).include?(value) }

  validates :value, inclusion: [TRUE_VALUE, FALSE_VALUE], allow_nil: true, allow_blank: false

  def true?
    value == TRUE_VALUE
  end

  def search_terms
    if true?
      [libelle]
    end
  end

  def to_s
    processed_value
  end

  def for_tag
    processed_value
  end

  def for_export
    processed_value
  end

  def for_api_v2
    true? ? 'true' : 'false'
  end

  private

  def processed_value
    true? ? 'Oui' : 'Non'
  end

  def set_value_to_nil
    self.value = nil
  end

  def set_value_to_false
    self.value = FALSE_VALUE
  end
end
