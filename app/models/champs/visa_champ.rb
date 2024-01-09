class Champs::VisaChamp < Champ
  def search_terms
    if value.present?
      [libelle]
    end
  end

  def user_accredited?(user)
    accredited_user_list.include?(user&.email)
  end
end
