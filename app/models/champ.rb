class Champ < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_de_champ
  delegate :libelle, :type_champs, :order_place, to: :type_de_champ
end
