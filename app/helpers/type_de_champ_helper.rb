module TypeDeChampHelper
  def tdc_options(current_administrateur)
    tdcs = TypeDeChamp.type_de_champs_list_fr

    if !current_administrateur.id.in?(Features.champ_pj_allowed_for_admin_ids)
      tdcs.reject! { |tdc| tdc.last == "piece_justificative" }
    end

    tdcs
  end
end
