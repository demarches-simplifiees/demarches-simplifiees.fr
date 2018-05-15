class Procedure < ApplicationRecord
  has_many :types_de_piece_justificative, -> { order "order_place ASC" }, dependent: :destroy
  has_many :types_de_champ, -> { public_only }, dependent: :destroy
  has_many :types_de_champ_private, -> { private_only }, class_name: 'TypeDeChamp', dependent: :destroy
  has_many :dossiers

  has_one :procedure_path, dependent: :destroy

  has_one :module_api_carto, dependent: :destroy
  has_one :attestation_template, dependent: :destroy

  belongs_to :administrateur
  belongs_to :parent_procedure, class_name: 'Procedure'

  has_many :assign_to, dependent: :destroy
  has_many :administrateurs_procedures
  has_many :administrateurs, through: :administrateurs_procedures
  has_many :gestionnaires, through: :assign_to

  has_one :initiated_mail, class_name: "Mails::InitiatedMail", dependent: :destroy
  has_one :received_mail, class_name: "Mails::ReceivedMail", dependent: :destroy
  has_one :closed_mail, class_name: "Mails::ClosedMail", dependent: :destroy
  has_one :refused_mail, class_name: "Mails::RefusedMail", dependent: :destroy
  has_one :without_continuation_mail, class_name: "Mails::WithoutContinuationMail", dependent: :destroy

  has_one_attached :notice

  delegate :use_api_carto, to: :module_api_carto

  accepts_nested_attributes_for :types_de_champ, :reject_if => proc { |attributes| attributes['libelle'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :types_de_piece_justificative, :reject_if => proc { |attributes| attributes['libelle'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :module_api_carto
  accepts_nested_attributes_for :types_de_champ_private

  mount_uploader :logo, ProcedureLogoUploader

  default_scope { where(hidden_at: nil) }
  scope :brouillons,            -> { where(published_at: nil).where(archived_at: nil) }
  scope :publiees,              -> { where.not(published_at: nil).where(archived_at: nil) }
  scope :archivees,             -> { where.not(archived_at: nil) }
  scope :publiees_ou_archivees, -> { where.not(published_at: nil) }
  scope :by_libelle,            -> { order(libelle: :asc) }
  scope :created_during,        -> (range) { where(created_at: range) }
  scope :cloned_from_library,   -> { where(cloned_from_library: true) }

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :description, presence: true, allow_blank: false, allow_nil: false
  validates :organisation, presence: true, allow_blank: false, allow_nil: false

  # Warning: dossier after_save build_default_champs must be removed
  # to save a dossier created from this method
  def new_dossier
    champs = types_de_champ
      .ordered
      .map { |tdc| tdc.champ.build }

    champs_private = types_de_champ_private
      .ordered
      .map { |tdc| tdc.champ.build }

    Dossier.new(procedure: self, champs: champs, champs_private: champs_private)
  end

  def hide!
    now = DateTime.now
    self.update(hidden_at: now)
    self.dossiers.update_all(hidden_at: now)
  end

  def path
    procedure_path.path if procedure_path.present?
  end

  def default_path
    libelle.parameterize.first(50)
  end

  def types_de_champ_ordered
    types_de_champ.order(:order_place)
  end

  def types_de_champ_private_ordered
    types_de_champ_private.order(:order_place)
  end

  def all_types_de_champ
    types_de_champ + types_de_champ_private
  end

  def self.active(id)
    publiees.find(id)
  end

  def switch_types_de_champ(index_of_first_element)
    switch_list_order(types_de_champ_ordered, index_of_first_element)
  end

  def switch_types_de_champ_private(index_of_first_element)
    switch_list_order(types_de_champ_private_ordered, index_of_first_element)
  end

  def switch_types_de_piece_justificative(index_of_first_element)
    switch_list_order(types_de_piece_justificative, index_of_first_element)
  end

  def switch_list_order(list, index_of_first_element)
    if index_of_first_element < 0 ||
      index_of_first_element == list.count - 1 ||
      list.count < 1

      false
    else
      list[index_of_first_element].update(order_place: index_of_first_element + 1)
      list[index_of_first_element + 1].update(order_place: index_of_first_element)

      true
    end
  end

  def locked?
    publiee_ou_archivee?
  end

  def clone(admin, from_library)
    procedure = self.deep_clone(include:
      {
        types_de_piece_justificative: nil,
        module_api_carto: nil,
        attestation_template: nil,
        types_de_champ: :drop_down_list,
        types_de_champ_private: :drop_down_list
      })
    procedure.archived_at = nil
    procedure.published_at = nil
    procedure.logo_secure_token = nil
    procedure.remote_logo_url = self.logo_url

    procedure.administrateur = admin
    procedure.initiated_mail = initiated_mail.try(:dup)
    procedure.received_mail = received_mail.try(:dup)
    procedure.closed_mail = closed_mail.try(:dup)
    procedure.refused_mail = refused_mail.try(:dup)
    procedure.without_continuation_mail = without_continuation_mail.try(:dup)

    procedure.cloned_from_library = from_library
    procedure.parent_procedure = self

    procedure
  end

  def brouillon?
    published_at.nil?
  end

  def publish!(path)
    now = Time.now
    self.update!({ test_started_at: now, published_at: now, archived_at: nil })
    ProcedurePath.create!(path: path, procedure: self, administrateur: self.administrateur)
  end

  def publiee?
    published_at.present? && archived_at.nil?
  end

  def archive
    self.update!(archived_at: Time.now)
  end

  def archivee?
    published_at.present? && archived_at.present?
  end

  def publiee_ou_archivee?
    publiee? || archivee?
  end

  def whitelisted?
    whitelisted_at.present?
  end

  def total_dossier
    self.dossiers.state_not_brouillon.size
  end

  def export_filename
    procedure_identifier = procedure_path&.path || "procedure-#{id}"
    "dossiers_#{procedure_identifier}_#{Time.now.strftime('%Y-%m-%d_%H-%M')}"
  end

  def generate_export
    exportable_dossiers = dossiers.downloadable_sorted

    headers = exportable_dossiers&.first&.export_headers || []
    data = exportable_dossiers.any? ? exportable_dossiers.map(&:export_values) : [[]]

    {
      headers: headers,
      data: data
    }
  end

  def procedure_overview(start_date)
    ProcedureOverview.new(self, start_date)
  end

  def initiated_mail_template
    initiated_mail || Mails::InitiatedMail.default_for_procedure(self)
  end

  def received_mail_template
    received_mail || Mails::ReceivedMail.default_for_procedure(self)
  end

  def closed_mail_template
    closed_mail || Mails::ClosedMail.default_for_procedure(self)
  end

  def refused_mail_template
    refused_mail || Mails::RefusedMail.default_for_procedure(self)
  end

  def without_continuation_mail_template
    without_continuation_mail || Mails::WithoutContinuationMail.default_for_procedure(self)
  end

  def fields
    fields = [
      field_hash('Créé le', 'self', 'created_at'),
      field_hash('Mis à jour le', 'self', 'updated_at'),
      field_hash('Demandeur', 'user', 'email')
    ]

    fields << [
      field_hash('Civilité (FC)', 'france_connect_information', 'gender'),
      field_hash('Prénom (FC)', 'france_connect_information', 'given_name'),
      field_hash('Nom (FC)', 'france_connect_information', 'family_name')
    ]

    if !for_individual || (for_individual && individual_with_siret)
      fields << [
        field_hash('SIREN', 'entreprise', 'siren'),
        field_hash('Forme juridique', 'entreprise', 'forme_juridique'),
        field_hash('Nom commercial', 'entreprise', 'nom_commercial'),
        field_hash('Raison sociale', 'entreprise', 'raison_sociale'),
        field_hash('SIRET siège social', 'entreprise', 'siret_siege_social'),
        field_hash('Date de création', 'entreprise', 'date_creation')
      ]

      fields << [
        field_hash('SIRET', 'etablissement', 'siret'),
        field_hash('Libellé NAF', 'etablissement', 'libelle_naf'),
        field_hash('Code postal', 'etablissement', 'code_postal')
      ]
    end

    types_de_champ
      .reject { |tdc| ['header_section', 'explication'].include?(tdc.type_champ) }
      .each do |type_de_champ|

      fields << field_hash(type_de_champ.libelle, 'type_de_champ', type_de_champ.id.to_s)
    end

    types_de_champ_private
      .reject { |tdc| ['header_section', 'explication'].include?(tdc.type_champ) }
      .each do |type_de_champ|

      fields << field_hash(type_de_champ.libelle, 'type_de_champ_private', type_de_champ.id.to_s)
    end

    fields.flatten
  end

  def fields_for_select
    fields.map do |field|
      [field['label'], "#{field['table']}/#{field['column']}"]
    end
  end

  def self.default_sort
    {
      'table' => 'self',
      'column' => 'id',
      'order' => 'desc'
    }.to_json
  end

  def whitelist!
    update_attribute('whitelisted_at', DateTime.now)
  end

  def closed_mail_template_attestation_inconsistency_state
    # As an optimization, don’t check the predefined templates (they are presumed correct)
    if closed_mail.present?
      tag_present = closed_mail.body.include?("--lien attestation--")
      if attestation_template&.activated? && !tag_present
        :missing_tag
      elsif !attestation_template&.activated? && tag_present
        :extraneous_tag
      end
    end
  end

  private

  def field_hash(label, table, column)
    {
      'label' => label,
      'table' => table,
      'column' => column
    }
  end
end
