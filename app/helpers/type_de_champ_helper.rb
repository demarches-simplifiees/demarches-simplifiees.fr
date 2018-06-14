module TypeDeChampHelper
  TOGGLES = {
    'piece_justificative' => :champ_pj?,
    'siret' => :champ_siret?,
    'linked_drop_down_list' => :champ_linked_dropdown?
  }

  def tdc_options
    tdcs = TypeDeChamp.type_de_champs_list_fr

    tdcs.select! do |tdc|
      toggle = TOGGLES[tdc.last]
      toggle.blank? || Flipflop.send(toggle)
    end

    tdcs
  end
end
