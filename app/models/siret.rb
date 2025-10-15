# frozen_string_literal: true

class Siret
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  attr_accessor :siret

  validates :siret, presence: true
  validates :siret, siret: true

  before_validation :remove_whitespace

  def remove_whitespace
    self.siret = siret.delete(' ') if siret.present?
  end
end
