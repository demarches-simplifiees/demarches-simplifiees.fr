class Champ < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :type_de_champ

  delegate :libelle, :type_champ, :order_place, :mandatory, to: :type_de_champ

  def mandatory?
    mandatory
  end

  def data_provide
    return 'datepicker' if type_champ == 'datetime'
    return 'typeahead' if type_champ == 'address'
  end
end
