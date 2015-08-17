class EvenementVie < ActiveRecord::Base
  has_many :formulaires

  def self.for_admi_facile
    where(use_admi_facile: true)
  end
end
