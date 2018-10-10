class ParcelleAgricole < ApplicationRecord
  belongs_to :dossier, touch: true

  def geometry
    JSON.parse(read_attribute(:geometry))
  end
end
