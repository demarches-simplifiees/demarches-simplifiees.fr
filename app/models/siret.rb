class Siret
  include ActiveModel::Model
  attr_accessor :siret

  validates_presence_of :siret
  validates :siret, siret_format: true
end
