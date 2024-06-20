class Siret
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  attr_accessor :siret

  validates :siret, presence: true
  validates :siret, siret_format: true

  before_validation :remove_whitespace

  def remove_whitespace
    if siret.present?
      siret.delete!(' ')
      siret.delete!('-')
    end
  end
end
