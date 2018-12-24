class Champs::CheckboxChamp < Champ
  def search_terms
    if value == 'on'
      [libelle]
    end
  end

  def to_s
    value == 'on' ? 'oui' : 'non'
  end
end
