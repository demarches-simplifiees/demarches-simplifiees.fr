class AnnuaireEducationUpdateJob < ApplicationJob
  def perform(champ)
    external_id = champ.external_id

    if external_id.present?
      data = APIEducation::AnnuaireEducationAdapter.new(external_id).to_params

      if data.present?
        champ.data = data
      else
        champ.external_id = nil
      end
      champ.save!
    end
  end
end
