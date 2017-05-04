class Dossier < ActiveRecord::Base
  enum state: {draft: 'draft',
               initiated: 'initiated',
               replied: 'replied', #action utilisateur demandé
               updated: 'updated', #etude par l'administration en cours
               received: 'received',
               closed: 'closed',
               refused: 'refused',
               without_continuation: 'without_continuation'
       }

  has_one :etablissement, dependent: :destroy
  has_one :entreprise, dependent: :destroy
  has_one :individual, dependent: :destroy
  has_many :cerfa, dependent: :destroy

  has_many :pieces_justificatives, dependent: :destroy
  has_many :champs, class_name: 'ChampPublic', dependent: :destroy
  has_many :champs_private, class_name: 'ChampPrivate', dependent: :destroy
  has_many :quartier_prioritaires, dependent: :destroy
  has_many :cadastres, dependent: :destroy
  has_many :commentaires, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :invites_user, class_name: 'InviteUser', dependent: :destroy
  has_many :invites_gestionnaires, class_name: 'InviteGestionnaire', dependent: :destroy
  has_many :follows
  has_many :notifications, dependent: :destroy

  belongs_to :procedure
  belongs_to :user

  accepts_nested_attributes_for :individual

  delegate :siren, to: :entreprise
  delegate :siret, to: :etablissement, allow_nil: true
  delegate :types_de_piece_justificative, to: :procedure
  delegate :types_de_champ, to: :procedure
  delegate :france_connect_information, to: :user

  before_validation :update_state_dates, if: -> { state_changed? }

  after_save :build_default_champs, if: Proc.new { procedure_id_changed? }
  after_save :build_default_individual, if: Proc.new { procedure.for_individual? }

  validates :user, presence: true

  BROUILLON = %w(draft)
  NOUVEAUX = %w(initiated)
  OUVERT = %w(updated replied)
  WAITING_FOR_GESTIONNAIRE = %w(updated)
  WAITING_FOR_USER = %w(replied)
  EN_CONSTRUCTION = %w(initiated updated replied)
  EN_INSTRUCTION = %w(received)
  A_INSTRUIRE = %w(received)
  TERMINE = %w(closed refused without_continuation)
  ALL_STATE = %w(initiated updated replied received closed refused without_continuation)

  def unreaded_notifications
    @unreaded_notif ||= notifications.where(already_read: false)
  end

  def first_unread_notification
    unreaded_notifications.order("created_at ASC").first
  end

  def retrieve_last_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).last
  end

  def retrieve_all_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).order(created_at: :DESC)
  end

  def build_default_champs
    procedure.types_de_champ.each do |type_de_champ|
      ChampPublic.create(type_de_champ_id: type_de_champ.id, dossier_id: id)
    end

    procedure.types_de_champ_private.each do |type_de_champ|
      ChampPrivate.create(type_de_champ_id: type_de_champ.id, dossier_id: id)
    end
  end

  def build_default_individual
    if Individual.where(dossier_id: self.id).count == 0
      Individual.create(dossier: self)
    end
  end

  def ordered_champs
    champs.joins(', types_de_champ').where("champs.type_de_champ_id = types_de_champ.id AND types_de_champ.procedure_id = #{procedure.id}").order('order_place')
  end

  def ordered_champs_private
    champs_private.joins(', types_de_champ').where("champs.type_de_champ_id = types_de_champ.id AND types_de_champ.procedure_id = #{procedure.id}").order('order_place')
  end

  def ordered_pieces_justificatives
    champs.joins(', types_de_piece_justificative').where("pieces_justificatives.type_de_piece_justificative_id = types_de_piece_justificative.id AND types_de_piece_justificative.procedure_id = #{procedure.id}").order('order_place ASC')
  end

  def ordered_commentaires
    commentaires.order(created_at: :desc)
  end

  def next_step! role, action
    unless %w(initiate follow update comment receive refuse without_continuation close).include?(action)
      fail 'action is not valid'
    end

    unless %w(user gestionnaire).include?(role)
      fail 'role is not valid'
    end

    case role
    when 'user'
      case action
      when 'initiate'
        if draft?
          initiated!
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
    when 'gestionnaire'
      case action
      when 'comment'
        if updated?
          replied!
        elsif initiated?
          replied!
        end
      when 'follow'
        if initiated?
          updated!
        end
      when 'close'
        if received?
          closed!
        end
      when 'refuse'
        if received?
          refused!
        end
      when 'without_continuation'
        if received?
          without_continuation!
        end
      end
    end

    state
  end

  def self.all_state order = 'ASC'
    where(state: ALL_STATE, archived: false).order("updated_at #{order}")
  end

  def brouillon?
    BROUILLON.include?(state)
  end

  scope :brouillon, -> { where(state: BROUILLON) }

  scope :order_by_updated_at, -> (order = :desc) { order(updated_at: order) }

  def self.nouveaux order = 'ASC'
    where(state: NOUVEAUX, archived: false).order("updated_at #{order}")
  end

  def self.waiting_for_gestionnaire order = 'ASC'
    where(state: WAITING_FOR_GESTIONNAIRE, archived: false).order("updated_at #{order}")
  end

  def self.waiting_for_user order = 'ASC'
    where(state: WAITING_FOR_USER, archived: false).order("updated_at #{order}")
  end

  scope :en_construction, -> { where(state: EN_CONSTRUCTION) }

  def self.ouvert order = 'ASC'
    where(state: OUVERT, archived: false).order("updated_at #{order}")
  end

  def self.a_instruire order = 'ASC'
    where(state: A_INSTRUIRE, archived: false).order("updated_at #{order}")
  end

  scope :en_instruction, -> { where(state: EN_INSTRUCTION) }

  scope :termine, -> { where(state: TERMINE) }

  scope :archived, -> { where(archived: true) }
  scope :not_archived, -> { where(archived: false) }

  scope :downloadable, -> { all_state }

  def cerfa_available?
    procedure.cerfa_flag? && cerfa.size != 0
  end

  def convert_specific_hash_values_to_string(hash_to_convert)
    hash = {}
    hash_to_convert.each do |key, value|
      value = serialize_value_for_export(value)
      hash.store(key, value)
    end
    return hash
  end

  def full_data_strings_array
    data_with_champs.map do |value|
      serialize_value_for_export(value)
    end
  end

  def export_entreprise_data
    unless entreprise.nil?
      etablissement_attr = EtablissementCsvSerializer.new(self.etablissement).attributes.map { |k, v| ["etablissement.#{k}".parameterize.underscore.to_sym, v] }.to_h
      entreprise_attr = EntrepriseSerializer.new(self.entreprise).attributes.map { |k, v| ["entreprise.#{k}".parameterize.underscore.to_sym, v] }.to_h
    else
      etablissement_attr = EtablissementSerializer.new(Etablissement.new).attributes.map { |k, v| ["etablissement.#{k}".parameterize.underscore.to_sym, v] }.to_h
      entreprise_attr = EntrepriseSerializer.new(Entreprise.new).attributes.map { |k, v| ["entreprise.#{k}".parameterize.underscore.to_sym, v] }.to_h
    end
    return convert_specific_hash_values_to_string(etablissement_attr.merge(entreprise_attr))
  end

  def data_with_champs
    serialized_dossier = DossierTableExportSerializer.new(self)
    data = serialized_dossier.attributes.values
    data += self.champs.order('type_de_champ_id ASC').map(&:value)
    data += self.export_entreprise_data.values
    return data
  end

  def export_headers
    serialized_dossier = DossierTableExportSerializer.new(self)
    headers = serialized_dossier.attributes.keys
    headers += self.procedure.types_de_champ.order('id ASC').map { |types_de_champ| types_de_champ.libelle.parameterize.underscore.to_sym }
    headers += self.export_entreprise_data.keys
    return headers
  end

  def followers_gestionnaires
    follows.includes(:gestionnaire).map(&:gestionnaire)
  end

  def reset!
    etablissement.destroy
    entreprise.destroy

    update_attributes(autorisation_donnees: false)
  end

  def total_follow
    follows.size
  end

  def read_only?
    received? || closed? || refused? || without_continuation?
  end

  def owner? email
    user.email == email
  end

  def invite_by_user? email
    (invites_user.pluck :email).include? email
  end

  def can_be_initiated?
    !(procedure.archived && draft?)
  end

  def text_summary
    if brouillon?
      parts = [
        "Dossier en brouillon répondant à la démarche ",
        procedure.libelle,
        " gérée par l'organisme ",
        procedure.organisation
      ]
    else
      parts = [
        "Dossier déposé le ",
        initiated_at.strftime("%d/%m/%Y"),
        " sur la démarche ",
        procedure.libelle,
        " gérée par l'organisme ",
        procedure.organisation
      ]
    end

    parts.join
  end

  private

  def update_state_dates
    if initiated? && !self.initiated_at
      self.initiated_at = DateTime.now
    elsif received? && !self.received_at
      self.received_at = DateTime.now
    elsif TERMINE.include?(state)
      self.processed_at = DateTime.now
    end
  end

  def serialize_value_for_export(value)
    value.nil? || value.kind_of?(Time) ? value : value.to_s
  end
end
