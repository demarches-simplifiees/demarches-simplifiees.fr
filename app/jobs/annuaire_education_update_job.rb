class AnnuaireEducationUpdateJob < ApplicationJob
  def perform(champ)
    search_term = champ.value

    if search_term.present?
      data = ApiEducation::AnnuaireEducationAdapter.new(search_term).to_params

      if data.present?
        champ.data = data
      else
        champ.value = nil
      end
      champ.save!
    end
  end
end
