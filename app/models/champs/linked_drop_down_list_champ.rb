class Champs::LinkedDropDownListChamp < Champ
  delegate :master_options, :slave_options, to: :type_de_champ
end
