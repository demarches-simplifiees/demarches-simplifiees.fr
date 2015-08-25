class Dossier < ActiveRecord::Base
  has_one :etablissement
  has_one :entreprise
  has_one :cerfa
  has_many :pieces_jointes
  belongs_to :formulaire
  has_many :commentaires

  delegate :siren, to: :entreprise
  delegate :siret, to: :etablissement
  delegate :types_piece_jointe, to: :formulaire

  before_create :build_default_cerfa

  after_save :build_default_pieces_jointes, if: Proc.new { formulaire_id_changed? }

  validates :mail_contact, format: { with: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/ }, unless: 'mail_contact.nil?'
  validates :nom_projet, presence: true, allow_blank: false, allow_nil: true
  validates :description, presence: true, allow_blank: false, allow_nil: true
  validates :montant_projet, presence: true, allow_blank: false, allow_nil: true
  validates :montant_aide_demande, presence: true, allow_blank: false, allow_nil: true
  validates :date_previsionnelle, presence: true, allow_blank: false,  unless: Proc.new { description.nil? }


  def retrieve_piece_jointe_by_type(type)
    pieces_jointes.where(type_piece_jointe_id: type).last
  end

  def build_default_pieces_jointes
    formulaire.types_piece_jointe.each do |type_piece_jointe|
      PieceJointe.create(type_piece_jointe_id: type_piece_jointe.id, dossier_id: id)
    end
  end

  def mailto
    "mailto:#{formulaire.email_contact}?subject=Demande%20de%20contact&body=Bonjour,%0A%0AJe%20vous%20informe%20que%20j'ai%20rempli%20le%20dossier%20sur%20admi_facile.%20Vous%20pouvez%20y%20acc%C3%A9der%20en%20suivant%20le%20lien%20suivant%20:%20%0Ahttps://admi_facile.apientreprise.fr/admin/dossiers/#{id}%20%0A%20Le%20num%C3%A9ro%20de%20mon%20dossier%20est%20le%20#{id}"
  end

  private

  def build_default_cerfa
    build_cerfa
    true
  end

end
