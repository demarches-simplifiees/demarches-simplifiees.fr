class Dossier < ActiveRecord::Base
  enum state: {draft: 'draft',
               initiated: 'initiated',
               replied: 'replied',
               updated: 'updated',
               validated: 'validated',
               submitted: 'submitted', #-submit_validated
               closed: 'closed'} #-processed

  has_one :etablissement, dependent: :destroy
  has_one :entreprise, dependent: :destroy
  has_one :cerfa, dependent: :destroy
  has_many :pieces_justificatives, dependent: :destroy
  has_many :champs, dependent: :destroy
  belongs_to :procedure
  belongs_to :user
  has_many :commentaires, dependent: :destroy

  delegate :siren, to: :entreprise
  delegate :siret, to: :etablissement
  delegate :types_de_piece_justificative, to: :procedure
  delegate :types_de_champs, to: :procedure

  before_create :build_default_cerfa

  after_save :build_default_pieces_justificatives, if: Proc.new { procedure_id_changed? }
  after_save :build_default_champs, if: Proc.new { procedure_id_changed? }

  validates :nom_projet, presence: true, allow_blank: false, allow_nil: true
  validates :description, presence: true, allow_blank: false, allow_nil: true
  validates :user, presence: true

  def retrieve_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).last
  end

  def build_default_pieces_justificatives

    procedure.types_de_piece_justificative.each do |type_de_piece_justificative|
      PieceJustificative.create(type_de_piece_justificative_id: type_de_piece_justificative.id, dossier_id: id)
    end
  end

  def build_default_champs
    procedure.types_de_champs.each do |type_de_champs|
      Champ.create(type_de_champs_id: type_de_champs.id, dossier_id: id)
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
    unless %w(initiate update comment valid submit close).include?(action)
      fail 'action is not valid'
    end

    unless %w(user gestionnaire).include?(role)
      fail 'role is not valid'
    end

    if role == 'user'
      case action
        when 'initiate'
          if draft?
            initiated!
          end
        when 'submit'
          if validated?
            submitted!
          end
        when 'update'
          if replied?
            updated!
          end
        when 'comment'
          if replied?
            updated!
          end
      end
    elsif role == 'gestionnaire'
      case action
        when 'comment'
          if updated?
            replied!
          elsif initiated?
            replied!
          end
        when 'valid'
          if updated?
            validated!
          elsif replied?
            validated!
          elsif initiated?
            validated!
          end
        when 'close'
          if submitted?
            closed!
          end
      end
    end
    state
  end

  def self.a_traiter
    Dossier.where("state='initiated' OR state='updated' OR state='submitted'").order('updated_at ASC')
  end

  def self.en_attente
    Dossier.where("state='replied' OR state='validated'").order('updated_at ASC')
  end

  def self.termine
    Dossier.where("state='closed'").order('updated_at ASC')
  end

  private

  def build_default_cerfa
    build_cerfa
    true
  end
end
