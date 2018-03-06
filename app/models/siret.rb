class Siret
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  attr_accessor :siret

  validates :siret, presence: true
  validates :siret, siret_format: true

  before_validation :remove_whitespace

  def remove_whitespace
    siret.delete!(' ') if siret.present?
  end
end
