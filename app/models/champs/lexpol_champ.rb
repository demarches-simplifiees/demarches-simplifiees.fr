class Champs::LexpolChamp < Champ
  def generate_or_update_lexpol_dossier
    if vale.blank?
      nor_number = APILexpol.new.create_dossier(model_id: '598706')
      self.value = nor_number
    else
      APILexpol.new.update_dossier(nor_number: value)
    end
    save!
  end
end
