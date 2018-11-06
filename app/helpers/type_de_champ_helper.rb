module TypeDeChampHelper
  TOGGLES = {
    TypeDeChamp.type_champs.fetch(:piece_justificative)   => :champ_pj?,
    TypeDeChamp.type_champs.fetch(:siret)                 => :champ_siret?,
    TypeDeChamp.type_champs.fetch(:linked_drop_down_list) => :champ_linked_dropdown?,
    TypeDeChamp.type_champs.fetch(:integer_number)        => :champ_integer_number?
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
