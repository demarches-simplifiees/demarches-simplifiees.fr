module TypeDeChampHelper
  def tdc_options(current_administrateur)
    tdcs = TypeDeChamp.type_de_champs_list_fr

    if !current_administrateur.feature_enabled?(:champ_pj_allowed)
      tdcs.reject! { |tdc| tdc.last == "piece_justificative" }
    end

    tdcs
  end
end
