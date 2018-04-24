module TypeDeChampHelper
  def tdc_options
    tdcs = TypeDeChamp.type_de_champs_list_fr

    if !Flipflop.champ_pj?
      tdcs.reject! { |tdc| tdc.last == "piece_justificative" }
    end

    if !Flipflop.champ_siret?
      tdcs.reject! { |tdc| tdc.last == "siret" }
    end

    tdcs
  end
end
