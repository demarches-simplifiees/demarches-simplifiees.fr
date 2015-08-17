class Formulaire < ActiveRecord::Base
  has_many :types_piece_jointe
  has_many :dossiers
  belongs_to :evenement_vie

  def self.for_admi_facile
    where(use_admi_facile: true)
  end
end
