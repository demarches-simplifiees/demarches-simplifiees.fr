class Champs::YesNoChamp < Champ
  def search_terms
    if true?
      [libelle]
    end
  end

  def to_s
    processed_value
  end

  def for_export
    processed_value
  end

  def true?
    value == 'true'
  end

  private

  def processed_value
    true? ? 'Oui' : 'Non'
  end
end
