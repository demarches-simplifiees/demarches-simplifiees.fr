class Champs::YesNoChamp < Champs::CheckboxChamp
  def search_terms
    if value == 'true'
      [libelle]
    end
  end

  def to_s
    value_for_export
  end

  private

  def value_for_export
    value == 'true' ? 'oui' : 'non'
  end
end
