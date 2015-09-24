class Dossier < ActiveRecord::Base
  enum state: { draft: 'draft',
      proposed: 'proposed',
      reply: 'reply',
      updated: 'updated',
      confirmed: 'confirmed',
      deposited: 'deposited',
      processed: 'processed' }

  has_one :etablissement, dependent: :destroy
  has_one :entreprise, dependent: :destroy
  has_one :cerfa, dependent: :destroy
  has_many :pieces_justificatives, dependent: :destroy
  belongs_to :procedure
  belongs_to :user
  has_many :commentaires, dependent: :destroy

  delegate :siren, to: :entreprise
  delegate :siret, to: :etablissement
  delegate :types_de_piece_justificative, to: :procedure

  before_create :build_default_cerfa

  after_save :build_default_pieces_justificatives, if: Proc.new { procedure_id_changed? }

  validates :nom_projet, presence: true, allow_blank: false, allow_nil: true
  validates :description, presence: true, allow_blank: false, allow_nil: true
  validates :montant_projet, presence: true, allow_blank: false, allow_nil: true
  validates :montant_aide_demande, presence: true, allow_blank: false, allow_nil: true
  validates :date_previsionnelle, presence: true, allow_blank: false,  unless: Proc.new { description.nil? }
  validates :user, presence: true

  def retrieve_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).last
  end

  def build_default_pieces_justificatives
    procedure.types_de_piece_justificative.each do |type_de_piece_justificative|
      PieceJustificative.create(type_de_piece_justificative_id: type_de_piece_justificative.id, dossier_id: id)
    end
  end

  def sous_domaine
    if Rails.env.production?
      'tps'
    else
      'tps-dev'
    end
  end

  def next_step! role, action
    unless ['propose', 'reply', 'update', 'comment', 'confirme', 'depose', 'process'].include?(action)
      fail 'action is not valid'
    end

    unless ['user', 'gestionnaire'].include?(role)
      fail 'role is not valid'
    end

    if role == 'user'
      case action
        when 'propose'
          if draft?
            proposed!
          end
        when 'depose'
          if confirmed?
            deposited!
          end
        when 'update'
          if reply?
            updated!
          end
        when 'comment'
          if reply?
            updated!
          end
      end
    elsif role == 'gestionnaire'
      case action
        when 'comment'
          if updated?
            reply!
          elsif proposed?
            reply!
          end
        when 'confirme'
          if updated?
            confirmed!
          elsif reply?
            confirmed!
          elsif proposed?
            confirmed!
          end
        when 'process'
          if deposited?
            processed!
          end
      end
    end
    state
  end

  def self.a_traiter
    Dossier.where("state='proposed' OR state='updated' OR state='deposited'").order('updated_at ASC')
  end

  def self.en_attente
    Dossier.where("state='reply' OR state='confirmed'").order('updated_at ASC')
  end

  def self.termine
    Dossier.where("state='processed'").order('updated_at ASC')
  end

  private

  def build_default_cerfa
    build_cerfa
    true
  end
end
