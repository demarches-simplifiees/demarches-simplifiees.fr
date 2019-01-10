class Champs::YesNoChamp < Champs::CheckboxChamp
  def search_terms
    if value == 'true'
      [libelle]
    end
  end

  def to_s
    processed_value
  end

  def for_export
    processed_value
  end

  def for_api
    processed_value
  end

  private

  def processed_value
    value == 'true' ? 'Oui' : 'Non'
  end
end
