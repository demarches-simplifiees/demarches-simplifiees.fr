class Dossier < ActiveRecord::Base
  enum state: {
    draft:                'draft',
    initiated:            'initiated',
    replied:              'replied',              # action utilisateur demandé
    updated:              'updated',              # etude par l'administration en cours
    received:             'received',
    closed:               'closed',
    refused:              'refused',
    without_continuation: 'without_continuation'
  }

  BROUILLON = %w(draft)
  NOUVEAUX = %w(initiated)
  OUVERT = %w(updated replied)
  WAITING_FOR_GESTIONNAIRE = %w(updated)
  EN_CONSTRUCTION = %w(initiated updated replied)
  EN_INSTRUCTION = %w(received)
  EN_CONSTRUCTION_OU_INSTRUCTION = EN_CONSTRUCTION + EN_INSTRUCTION
  A_INSTRUIRE = %w(received)
  TERMINE = %w(closed refused without_continuation)

  has_one :etablissement, dependent: :destroy
  has_one :entreprise, dependent: :destroy
  has_one :individual, dependent: :destroy
  has_one :attestation
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
  has_many :avis, dependent: :destroy

  belongs_to :procedure
  belongs_to :user

  accepts_nested_attributes_for :champs
  accepts_nested_attributes_for :champs_private

  default_scope { where(hidden_at: nil) }
  scope :state_brouillon,                      -> { where(state: BROUILLON) }
  scope :state_not_brouillon,                  -> { where.not(state: BROUILLON) }
  scope :state_nouveaux,                       -> { where(state: NOUVEAUX) }
  scope :state_ouvert,                         -> { where(state: OUVERT) }
  scope :state_waiting_for_gestionnaire,       -> { where(state: WAITING_FOR_GESTIONNAIRE) }
  scope :state_en_construction,                -> { where(state: EN_CONSTRUCTION) }
  scope :state_en_instruction,                 -> { where(state: EN_INSTRUCTION) }
  scope :state_en_construction_ou_instruction, -> { where(state: EN_CONSTRUCTION_OU_INSTRUCTION) }
  scope :state_a_instruire,                    -> { where(state: A_INSTRUIRE) }
  scope :state_termine,                        -> { where(state: TERMINE) }

  scope :archived,      -> { where(archived: true) }
  scope :not_archived,  -> { where(archived: false) }

  scope :order_by_updated_at, -> (order = :desc) { order(updated_at: order) }

  scope :all_state,                   -> { not_archived.state_not_brouillon.order_by_updated_at(:asc) }
  scope :nouveaux,                    -> { not_archived.state_nouveaux.order_by_updated_at(:asc) }
  scope :ouvert,                      -> { not_archived.state_ouvert.order_by_updated_at(:asc) }
  scope :waiting_for_gestionnaire,    -> { not_archived.state_waiting_for_gestionnaire.order_by_updated_at(:asc) }
  scope :a_instruire,                 -> { not_archived.state_a_instruire.order_by_updated_at(:asc) }
  scope :termine,                     -> { not_archived.state_termine.order_by_updated_at(:asc) }
  scope :downloadable,                -> { state_not_brouillon.order_by_updated_at(:asc) }
  scope :en_cours,                    -> { not_archived.state_en_construction_ou_instruction.order_by_updated_at(:asc) }
  scope :without_followers,           -> { includes(:follows).where(follows: { id: nil }) }
  scope :with_unread_notifications,   -> { where(notifications: { already_read: false }) }

  accepts_nested_attributes_for :individual

  delegate :siren, to: :entreprise
  delegate :siret, to: :etablissement, allow_nil: true
  delegate :types_de_piece_justificative, to: :procedure
  delegate :types_de_champ, to: :procedure
  delegate :france_connect_information, to: :user

  before_validation :update_state_dates, if: -> { state_changed? }

  after_save :build_default_champs, if: Proc.new { procedure_id_changed? }
  after_save :build_default_individual, if: Proc.new { procedure.for_individual? }
  after_save :send_notification_email

  validates :user, presence: true

  def unreaded_notifications
    @unreaded_notif ||= notifications.where(already_read: false)
  end

  def first_unread_notification
    unreaded_notifications.order("created_at ASC").first
  end

  def was_piece_justificative_uploaded_for_type_id?(type_id)
    pieces_justificatives.where(type_de_piece_justificative_id: type_id).count > 0
  end

  def notifications_summary
    unread_notifications = notifications.unread

    {
      demande: unread_notifications.select(&:demande?).present?,
      instruction: unread_notifications.select(&:instruction?).present?,
      messagerie: unread_notifications.select(&:messagerie?).present?
    }
  end

  def retrieve_last_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).last
  end

  def retrieve_all_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).order(created_at: :DESC)
  end

  def build_default_champs
    procedure.types_de_champ.all.each do |type_de_champ|
      ChampPublic.create(type_de_champ: type_de_champ, dossier: self)
    end

    procedure.types_de_champ_private.all.each do |type_de_champ|
      ChampPrivate.create(type_de_champ: type_de_champ, dossier: self)
    end
  end

  def build_default_individual
    if Individual.where(dossier_id: self.id).count == 0
      Individual.create(dossier: self)
    end
  end

  def ordered_champs
    # TODO: use the line below when the procedure preview does not leak champ with dossier_id == 0
    # champs.joins(:type_de_champ).order('types_de_champ.order_place')
    champs.joins(', types_de_champ').where("champs.type_de_champ_id = types_de_champ.id AND types_de_champ.procedure_id = #{procedure.id}").order('order_place')
  end

  def ordered_champs_private
    # TODO: use the line below when the procedure preview does not leak champ with dossier_id == 0
    # champs_private.includes(:type_de_champ).order('types_de_champ.order_place')
    champs_private.joins(', types_de_champ').where("champs.type_de_champ_id = types_de_champ.id AND types_de_champ.procedure_id = #{procedure.id}").order('order_place')
  end

  def ordered_pieces_justificatives
    champs.joins(', types_de_piece_justificative').where("pieces_justificatives.type_de_piece_justificative_id = types_de_piece_justificative.id AND types_de_piece_justificative.procedure_id = #{procedure.id}").order('order_place ASC')
  end

  def next_step! role, action, motivation = nil
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
          self.attestation = build_attestation
          save

          closed!

          if motivation
            self.motivation = motivation
            save
          end
        end
      when 'refuse'
        if received?
          refused!

          if motivation
            self.motivation = motivation
            save
          end
        end
      when 'without_continuation'
        if received?
          without_continuation!

          if motivation
            self.motivation = motivation
            save
          end
        end
      end
    end

    state
  end

  def brouillon?
    BROUILLON.include?(state)
  end

  def en_construction?
    EN_CONSTRUCTION.include?(state)
  end

  def en_instruction?
    EN_INSTRUCTION.include?(state)
  end

  def en_construction_ou_instruction?
    EN_CONSTRUCTION_OU_INSTRUCTION.include?(state)
  end

  def termine?
    TERMINE.include?(state)
  end

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
    data += self.ordered_champs.map(&:value)
    data += self.ordered_champs_private.map(&:value)
    data += self.export_entreprise_data.values
    return data
  end

  def export_headers
    serialized_dossier = DossierTableExportSerializer.new(self)
    headers = serialized_dossier.attributes.keys
    headers += self.procedure.types_de_champ.order(:order_place).map { |types_de_champ| types_de_champ.libelle.parameterize.underscore.to_sym }
    headers += self.procedure.types_de_champ_private.order(:order_place).map { |types_de_champ| types_de_champ.libelle.parameterize.underscore.to_sym }
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
    !(procedure.archivee? && draft?)
  end

  def text_summary
    if brouillon?
      parts = [
        "Dossier en brouillon répondant à la procédure ",
        procedure.libelle,
        " gérée par l'organisme ",
        procedure.organisation
      ]
    else
      parts = [
        "Dossier déposé le ",
        initiated_at.localtime.strftime("%d/%m/%Y"),
        " sur la procédure ",
        procedure.libelle,
        " gérée par l'organisme ",
        procedure.organisation
      ]
    end

    parts.join
  end

  def avis_for(gestionnaire)
    if gestionnaire.dossiers.include?(self)
      avis.order(created_at: :asc)
    else
      avis
        .where(confidentiel: false)
        .or(avis.where(claimant: gestionnaire))
        .or(avis.where(gestionnaire: gestionnaire))
        .order(created_at: :asc)
    end
  end

  private

  def build_attestation
    if procedure.attestation_template.present? && procedure.attestation_template.activated?
      procedure.attestation_template.attestation_for(self)
    end
  end

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

  def send_notification_email
    if state_changed? && EN_INSTRUCTION.include?(state)
      NotificationMailer.send_notification(self, procedure.received_mail_template).deliver_now!
    end
  end
end
