class Dossier < ApplicationRecord
  enum state: {
    brouillon:       'brouillon',
    en_construction: 'en_construction',
    en_instruction:  'en_instruction',
    accepte:         'accepte',
    refuse:          'refuse',
    sans_suite:      'sans_suite'
  }

  EN_CONSTRUCTION_OU_INSTRUCTION = %w(en_construction en_instruction)
  TERMINE = %w(accepte refuse sans_suite)
  INSTRUCTION_COMMENCEE = TERMINE + %w(en_instruction)
  SOUMIS = EN_CONSTRUCTION_OU_INSTRUCTION + TERMINE

  has_one :etablissement, dependent: :destroy
  has_one :entreprise, dependent: :destroy
  has_one :individual, dependent: :destroy
  has_one :attestation
  has_many :cerfa, dependent: :destroy

  has_many :pieces_justificatives, dependent: :destroy
  has_many :champs, -> { public_only }, dependent: :destroy
  has_many :champs_private, -> { private_only }, class_name: 'Champ', dependent: :destroy
  has_many :quartier_prioritaires, dependent: :destroy
  has_many :cadastres, dependent: :destroy
  has_many :commentaires, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :invites_user, class_name: 'InviteUser', dependent: :destroy
  has_many :invites_gestionnaires, class_name: 'InviteGestionnaire', dependent: :destroy
  has_many :follows
  has_many :avis, dependent: :destroy

  belongs_to :procedure
  belongs_to :user

  accepts_nested_attributes_for :champs
  accepts_nested_attributes_for :champs_private

  validates :autorisation_donnees, acceptance: { message: 'doit être coché' }, allow_nil: false, on: :update

  default_scope { where(hidden_at: nil) }
  scope :state_brouillon,                      -> { where(state: 'brouillon') }
  scope :state_not_brouillon,                  -> { where.not(state: 'brouillon') }
  scope :state_en_construction,                -> { where(state: 'en_construction') }
  scope :state_en_instruction,                 -> { where(state: 'en_instruction') }
  scope :state_en_construction_ou_instruction, -> { where(state: EN_CONSTRUCTION_OU_INSTRUCTION) }
  scope :state_termine,                        -> { where(state: TERMINE) }

  scope :archived,      -> { where(archived: true) }
  scope :not_archived,  -> { where(archived: false) }

  scope :order_by_updated_at, -> (order = :desc) { order(updated_at: order) }

  scope :all_state,                   -> { not_archived.state_not_brouillon }
  scope :en_construction,             -> { not_archived.state_en_construction }
  scope :en_instruction,              -> { not_archived.state_en_instruction }
  scope :termine,                     -> { not_archived.state_termine }
  scope :downloadable_sorted,         -> { state_not_brouillon.includes(:entreprise, :etablissement, :champs, :champs_private).order(en_construction_at: 'asc') }
  scope :en_cours,                    -> { not_archived.state_en_construction_ou_instruction }
  scope :without_followers,           -> { left_outer_joins(:follows).where(follows: { id: nil }) }
  scope :followed_by,                 -> (gestionnaire) { joins(:follows).where(follows: { gestionnaire: gestionnaire }) }
  scope :with_ordered_champs,         -> { includes(champs: :type_de_champ).order('types_de_champ.order_place') }

  accepts_nested_attributes_for :individual

  delegate :siren, to: :entreprise
  delegate :siret, to: :etablissement, allow_nil: true
  delegate :types_de_piece_justificative, to: :procedure
  delegate :types_de_champ, to: :procedure
  delegate :france_connect_information, to: :user

  before_validation :update_state_dates, if: -> { state_changed? }

  after_save :build_default_champs, if: Proc.new { saved_change_to_procedure_id? }
  after_save :build_default_individual, if: Proc.new { procedure.for_individual? }
  after_save :send_dossier_received
  after_save :send_web_hook
  after_create :send_draft_notification_email

  validates :user, presence: true

  def was_piece_justificative_uploaded_for_type_id?(type_id)
    pieces_justificatives.where(type_de_piece_justificative_id: type_id).count > 0
  end

  def retrieve_last_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).last
  end

  def retrieve_all_piece_justificative_by_type(type)
    pieces_justificatives.where(type_de_piece_justificative_id: type).order(created_at: :DESC)
  end

  def build_default_champs
    procedure.all_types_de_champ.each do |type_de_champ|
      type_de_champ.champ.create(dossier: self)
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
    hash_to_convert.transform_values do |value|
      serialize_value_for_export(value)
    end
  end

  def export_etablissement_data
    if etablissement.present?
      etablissement_attr = EtablissementCsvSerializer.new(self.etablissement).attributes.transform_keys { |k| "etablissement.#{k}".parameterize.underscore.to_sym }
      entreprise_attr = EntrepriseSerializer.new(self.entreprise).attributes.transform_keys { |k| "entreprise.#{k}".parameterize.underscore.to_sym }
    else
      etablissement_attr = EtablissementSerializer.new(Etablissement.new).attributes.transform_keys { |k| "etablissement.#{k}".parameterize.underscore.to_sym }
      entreprise_attr = EntrepriseSerializer.new(Entreprise.new).attributes.transform_keys { |k| "entreprise.#{k}".parameterize.underscore.to_sym }
    end
    convert_specific_hash_values_to_string(etablissement_attr.merge(entreprise_attr))
  end

  def to_sorted_values
    serialized_dossier = DossierTableExportSerializer.new(self)
    values = serialized_dossier.attributes.values
    values += self.ordered_champs.map(&:for_export)
    values += self.ordered_champs_private.map(&:for_export)
    values += self.export_etablissement_data.values
    values
  end

  def export_headers
    serialized_dossier = DossierTableExportSerializer.new(self)
    headers = serialized_dossier.attributes.keys
    headers += self.procedure.types_de_champ.order(:order_place).map { |types_de_champ| types_de_champ.libelle.parameterize.underscore.to_sym }
    headers += self.procedure.types_de_champ_private.order(:order_place).map { |types_de_champ| types_de_champ.libelle.parameterize.underscore.to_sym }
    headers += self.export_etablissement_data.keys
    headers
  end

  def export_values
    to_sorted_values.map do |value|
      serialize_value_for_export(value)
    end
  end

  def followers_gestionnaires
    follows.includes(:gestionnaire).map(&:gestionnaire)
  end

  def reset!
    etablissement.destroy

    update_columns(autorisation_donnees: false)
  end

  def total_follow
    follows.size
  end

  def read_only?
    en_instruction? || accepte? || refuse? || sans_suite?
  end

  def owner_or_invite?(user)
    self.user == user || invite_for_user(user).present?
  end

  def invite_for_user(user)
    invites_user.find_by(user_id: user.id)
  end

  def can_be_en_construction?
    !(procedure.archivee? && brouillon?)
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
        en_construction_at.localtime.strftime("%d/%m/%Y"),
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

  def get_value(table, column)
    case table
    when 'self'
      self.send(column)
    when 'user'
      self.user.send(column)
    when 'france_connect_information'
      self.user.france_connect_information&.send(column)
    when 'entreprise'
      self.entreprise&.send(column)
    when 'etablissement'
      self.etablissement&.send(column)
    when 'type_de_champ'
      self.champs.find { |c| c.type_de_champ_id == column.to_i }.value
    when 'type_de_champ_private'
      self.champs_private.find { |c| c.type_de_champ_id == column.to_i }.value
    end
  end

  def self.sanitize_for_order(order)
    sanitize_sql_for_order(order)
  end

  def owner_name
    if entreprise.present?
      entreprise.raison_sociale
    elsif individual.present?
      "#{individual.nom} #{individual.prenom}"
    end
  end

  def statut
    if accepte?
      'accepté'
    elsif sans_suite?
      'classé sans suite'
    elsif refuse?
      'refusé'
    end
  end

  def user_geometry
    if json_latlngs.present?
      UserGeometry.new(json_latlngs)
    end
  end

  def unspecified_attestation_champs
    attestation_template = procedure.attestation_template

    if attestation_template&.activated?
      attestation_template.unspecified_champs_for_dossier(self)
    else
      []
    end
  end

  def build_attestation
    if procedure.attestation_template&.activated?
      procedure.attestation_template.attestation_for(self)
    end
  end

  private

  def update_state_dates
    if en_construction? && !self.en_construction_at
      self.en_construction_at = DateTime.now
    elsif en_instruction? && !self.en_instruction_at
      self.en_instruction_at = DateTime.now
    elsif TERMINE.include?(state)
      self.processed_at = DateTime.now
    end
  end

  def serialize_value_for_export(value)
    value.nil? || value.kind_of?(Time) ? value : value.to_s
  end

  def send_dossier_received
    if saved_change_to_state? && en_instruction?
      NotificationMailer.send_dossier_received(id).deliver_later
    end
  end

  def send_draft_notification_email
    if brouillon?
      NotificationMailer.send_draft_notification(self).deliver_now!
    end
  end

  def send_web_hook
    if saved_change_to_state? && !brouillon? && procedure.web_hook_url
      WebHookJob.perform_later(
        procedure,
        self
      )
    end
  end
end
