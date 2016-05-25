class Siret
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  attr_accessor :siret

  validates_presence_of :siret
  validates :siret, siret_format: true

  before_validation :remove_whitespace

  def remove_whitespace
    siret.delete!(' ') unless siret.nil?
  end
end
