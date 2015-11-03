class Champs < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_de_champs
  delegate :libelle, :type_champs, :order_place, to: :type_de_champs

end
