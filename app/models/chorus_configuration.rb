class ChorusConfiguration
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :centre_de_coup, default: nil
  attribute :domaine_fonctionnel, default: nil
  attribute :referentiel_de_programmation, default: nil

  validates :centre_de_coup, inclusion: { in: Proc.new { ChorusConfiguration.centre_de_coup_options } }
  validates :domaine_fonctionnel, inclusion: { in: Proc.new { ChorusConfiguration.domaine_fonctionnel_options } }
  validates :referentiel_de_programmation, inclusion: { in: Proc.new { ChorusConfiguration.referentiel_de_programmation_options } }

  def self.centre_de_coup_options
    [1, 2, 3].map(&:to_s)
  end

  def self.domaine_fonctionnel_options
    [4, 5, 6].map(&:to_s)
  end

  def self.referentiel_de_programmation_options
    [7, 8, 9].map(&:to_s)
  end
end
