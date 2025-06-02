# frozen_string_literal: true

class Champs::VisaChamp < Champ
  def search_terms
    if value.present?
      [value]
    end
  end

  def user_accredited?(user)
    accredited_user_list.include?(user&.email)
  end
end
