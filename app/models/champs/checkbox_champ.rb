class Champs::CheckboxChamp < Champ
  def search_terms
    if value == 'on'
      [ libelle ]
    end
  end
end
