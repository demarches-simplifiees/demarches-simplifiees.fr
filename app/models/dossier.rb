class Dossier < ApplicationRecord
  enum state: {
    brouillon:       'brouillon',
    en_construction: 'en_construction',
    en_instruction:  'en_instruction',
    accepte:         'accepte',
    refuse:          'refuse',
    sans_suite:      'sans_suite'
  }

  EN_CONSTRUCTION_OU_INSTRUCTION = [states.fetch(:en_construction), states.fetch(:en_instruction)]
  TERMINE = [states.fetch(:accepte), states.fetch(:refuse), states.fetch(:sans_suite)]
  INSTRUCTION_COMMENCEE = TERMINE + [states.fetch(:en_instruction)]
  SOUMIS = EN_CONSTRUCTION_OU_INSTRUCTION + TERMINE

  has_one :etablissement, dependent: :destroy
  has_one :individual, dependent: :destroy
  has_one :attestation

  has_many :pieces_justificatives, dependent: :destroy
  has_many :champs, -> { public_only.ordered }, dependent: :destroy
  has_many :champs_private, -> { private_only.ordered }, class_name: 'Champ', dependent: :destroy
  has_many :quartier_prioritaires, dependent: :destroy
  has_many :cadastres, dependent: :destroy
  has_many :commentaires, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :invites_user, class_name: 'InviteUser', dependent: :destroy
  has_many :invites_gestionnaires, class_name: 'InviteGestionnaire', dependent: :destroy
  has_many :follows
  has_many :followers_gestionnaires, through: :follows, source: :gestionnaire
  has_many :avis, dependent: :destroy

  belongs_to :procedure
  belongs_to :user

  accepts_nested_attributes_for :champs
  accepts_nested_attributes_for :champs_private

  default_scope { where(hidden_at: nil) }
  scope :state_brouillon,                      -> { where(state: states.fetch(:brouillon)) }
  scope :state_not_brouillon,                  -> { where.not(state: states.fetch(:brouillon)) }
  scope :state_en_construction,                -> { where(state: states.fetch(:en_construction)) }
  scope :state_en_instruction,                 -> { where(state: states.fetch(:en_instruction)) }
  scope :state_en_construction_ou_instruction, -> { where(state: EN_CONSTRUCTION_OU_INSTRUCTION) }
  scope :state_instruction_commencee,          -> { where(state: INSTRUCTION_COMMENCEE) }
  scope :state_termine,                        -> { where(state: TERMINE) }

  scope :archived,      -> { where(archived: true) }
  scope :not_archived,  -> { where(archived: false) }

  scope :order_by_updated_at, -> (order = :desc) { order(updated_at: order) }

  scope :all_state,                   -> { not_archived.state_not_brouillon }
  scope :en_construction,             -> { not_archived.state_en_construction }
  scope :en_instruction,              -> { not_archived.state_en_instruction }
  scope :termine,                     -> { not_archived.state_termine }
  scope :downloadable_sorted,         -> { state_not_brouillon.includes(:etablissement, :champs, :champs_private, :user, :individual, :followers_gestionnaires).order(en_construction_at: 'asc') }
  scope :en_cours,                    -> { not_archived.state_en_construction_ou_instruction }
  scope :without_followers,           -> { left_outer_joins(:follows).where(follows: { id: nil }) }
  scope :followed_by,                 -> (gestionnaire) { joins(:follows).where(follows: { gestionnaire: gestionnaire }) }
  scope :with_champs,                 -> { includes(champs: :type_de_champ) }
  scope :nearing_end_of_retention,    -> (duration = '1 month') { joins(:procedure).where("en_instruction_at + (duree_conservation_dossiers_dans_ds * interval '1 month') - now() < interval ?", duration) }

  accepts_nested_attributes_for :individual

  delegate :siret, :siren, to: :etablissement, allow_nil: true
  delegate :types_de_piece_justificative, to: :procedure
  delegate :types_de_champ, to: :procedure
  delegate :france_connect_information, to: :user

  before_validation :update_state_dates, if: -> { state_changed? }

  before_save :build_default_champs, if: Proc.new { procedure_id_changed? }
  before_save :build_default_individual, if: Proc.new { procedure.for_individual? }
  before_save :update_search_terms

  after_save :send_dossier_received
  after_save :send_web_hook
  after_create :send_draft_notification_email

  validates :user, presence: true

  def update_search_terms
    self.search_terms = [
      user&.email,
      france_connect_information&.given_name,
      france_connect_information&.family_name,
      *champs.flat_map(&:search_terms),
      *etablissement&.search_terms,
      individual&.nom,
      individual&.prenom
    ].compact.join(' ')
    self.private_search_terms = champs_private.flat_map(&:search_terms).compact.join(' ')
  end

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
    procedure.types_de_champ.each do |type_de_champ|
      champs << type_de_champ.champ.build
    end
    procedure.types_de_champ_private.each do |type_de_champ|
      champs_private << type_de_champ.champ.build
    end
  end

  def build_default_individual
    if Individual.where(dossier_id: self.id).count == 0
      build_individual
    end
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

  def instruction_commencee?
    INSTRUCTION_COMMENCEE.include?(state)
  end

  def export_headers
    serialized_dossier = DossierTableExportSerializer.new(self)
    headers = serialized_dossier.attributes.keys
    headers += procedure.types_de_champ.order(:order_place).map { |types_de_champ| types_de_champ.libelle.parameterize.underscore.to_sym }
    headers += procedure.types_de_champ_private.order(:order_place).map { |types_de_champ| types_de_champ.libelle.parameterize.underscore.to_sym }
    headers += export_etablissement_data.keys
    headers
  end

  def export_values
    sorted_values.map do |value|
      serialize_value_for_export(value)
    end
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

  def invite_for_user(user)
    invites_user.find_by(user_id: user.id)
  end

  def can_be_en_construction?
    !(procedure.archivee? && brouillon?)
  end

  def can_transition_to_en_construction?
    !procedure.archivee? && brouillon?
  end

  def can_be_updated_by_the_user?
    brouillon? || en_construction?
  end

  def retention_end_date
    if instruction_commencee?
      en_instruction_at + procedure.duree_conservation_dossiers_dans_ds.months
    end
  end

  def retention_expired?
    instruction_commencee? && retention_end_date <= DateTime.now
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
        en_construction_at.localtime.strftime("%d/%m/%Y"),
        " sur la démarche ",
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
    DossierFieldService.get_value(self, table, column)
  end

  def owner_name
    if etablissement.present?
      etablissement.entreprise_raison_sociale
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

  def delete_and_keep_track
    now = Time.now
    deleted_dossier = DeletedDossier.create!(dossier_id: id, procedure: procedure, state: state, deleted_at: now)
    update(hidden_at: now)

    if en_construction?
      administration_emails = followers_gestionnaires.present? ? followers_gestionnaires.pluck(:email) : [procedure.administrateur.email]
      administration_emails.each do |email|
        DossierMailer.notify_deletion_to_administration(deleted_dossier, email).deliver_later
      end
    end
    DossierMailer.notify_deletion_to_user(deleted_dossier, user.email).deliver_later
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

  def convert_specific_hash_values_to_string(hash_to_convert)
    hash_to_convert.transform_values do |value|
      serialize_value_for_export(value)
    end
  end

  def export_etablissement_data
    if etablissement.present?
      etablissement_attr = EtablissementCsvSerializer.new(etablissement).attributes.transform_keys { |k| "etablissement.#{k}".parameterize.underscore.to_sym }
      entreprise_attr = EntrepriseSerializer.new(etablissement.entreprise).attributes.transform_keys { |k| "entreprise.#{k}".parameterize.underscore.to_sym }
    else
      etablissement_attr = EtablissementSerializer.new(Etablissement.new).attributes.transform_keys { |k| "etablissement.#{k}".parameterize.underscore.to_sym }
      entreprise_attr = EntrepriseSerializer.new(Entreprise.new).attributes.transform_keys { |k| "entreprise.#{k}".parameterize.underscore.to_sym }
    end
    convert_specific_hash_values_to_string(etablissement_attr.merge(entreprise_attr))
  end

  def sorted_values
    serialized_dossier = DossierTableExportSerializer.new(self)
    values = serialized_dossier.attributes.values
    values += champs.map(&:for_export)
    values += champs_private.map(&:for_export)
    values += export_etablissement_data.values
    values
  end

  def send_dossier_received
    if saved_change_to_state? && en_instruction?
      NotificationMailer.send_dossier_received(self).deliver_later
    end
  end

  def send_draft_notification_email
    if brouillon?
      NotificationMailer.send_draft_notification(self).deliver_later
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
