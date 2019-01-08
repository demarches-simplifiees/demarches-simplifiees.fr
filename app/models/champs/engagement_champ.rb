class Champs::EngagementChamp < Champs::CheckboxChamp
  def search_terms
    if value == 'on'
      [libelle]
    end
  end
end
