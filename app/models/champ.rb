class Champ < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_de_champ

  delegate :libelle, :type_champ, :order_place, :mandatory, to: :type_de_champ

  def mandatory?
    mandatory
  end
end
