class Champs::CheckboxChamp < Champ
  def search_terms
    if value == 'on'
      [libelle]
    end
  end

  def to_s
    value == 'on' ? 'oui' : 'non'
  end

  def for_export
    value == 'on' ? 'on' : 'off'
  end
end
