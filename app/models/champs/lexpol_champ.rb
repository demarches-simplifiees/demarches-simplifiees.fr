class Champs::LexpolChamp < Champ
  store_accessor :data, :lexpol_status, :lexpol_dossier_url

  def generate_or_update_lexpol_dossier
    model_id   = type_de_champ.lexpol_modele.presence
    lexpol_api = APILexpol.new

    if value.blank?
      nor_number = lexpol_api.create_dossier(model_id)
      self.value = nor_number
    else
      lexpol_api.update_dossier(value)
    end
    save!
  end
end
