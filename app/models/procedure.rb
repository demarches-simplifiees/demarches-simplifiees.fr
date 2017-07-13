class Procedure < ActiveRecord::Base
  has_many :types_de_piece_justificative, -> { order "order_place ASC" }, dependent: :destroy
  has_many :types_de_champ, class_name: 'TypeDeChampPublic', dependent: :destroy
  has_many :types_de_champ_private, dependent: :destroy
  has_many :dossiers

  has_one :procedure_path, dependent: :destroy

  has_one :module_api_carto, dependent: :destroy
  has_one :attestation_template, dependent: :destroy

  belongs_to :administrateur

  has_many :assign_to, dependent: :destroy
  has_many :gestionnaires, through: :assign_to

  has_many :preference_list_dossiers

  has_one :initiated_mail, class_name: "Mails::InitiatedMail", dependent: :destroy
  has_one :received_mail, class_name: "Mails::ReceivedMail", dependent: :destroy
  has_one :closed_mail, class_name: "Mails::ClosedMail", dependent: :destroy
  has_one :refused_mail, class_name: "Mails::RefusedMail", dependent: :destroy
  has_one :without_continuation_mail, class_name: "Mails::WithoutContinuationMail", dependent: :destroy

  delegate :use_api_carto, to: :module_api_carto

  accepts_nested_attributes_for :types_de_champ, :reject_if => proc { |attributes| attributes['libelle'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :types_de_piece_justificative, :reject_if => proc { |attributes| attributes['libelle'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :module_api_carto
  accepts_nested_attributes_for :types_de_champ_private

  mount_uploader :logo, ProcedureLogoUploader

  default_scope { where(hidden_at: nil) }
  scope :brouillons,          -> { where(published_at: nil).where(archived_at: nil) }
  scope :publiees,            -> { where.not(published_at: nil).where(archived_at: nil) }
  scope :archivees,           -> { where.not(archived_at: nil) }
  scope :publiee_ou_archivee, -> { where.not(published_at: nil) }
  scope :by_libelle,          -> { order(libelle: :asc) }

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :description, presence: true, allow_blank: false, allow_nil: false

  def hide!
    now = DateTime.now
    self.update_attributes(hidden_at: now)
    self.dossiers.update_all(hidden_at: now)
  end

  def path
    procedure_path.path unless procedure_path.nil?
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

  def self.active id
    publiees.find(id)
  end

  def switch_types_de_champ index_of_first_element
    switch_list_order(types_de_champ_ordered, index_of_first_element)
  end

  def switch_types_de_champ_private index_of_first_element
    switch_list_order(types_de_champ_private_ordered, index_of_first_element)
  end

  def switch_types_de_piece_justificative index_of_first_element
    switch_list_order(types_de_piece_justificative, index_of_first_element)
  end

  def switch_list_order(list, index_of_first_element)
    if index_of_first_element < 0 ||
      index_of_first_element == list.count - 1 ||
      list.count < 1

      false
    else
      list[index_of_first_element].update_attributes(order_place: index_of_first_element + 1)
      list[index_of_first_element + 1].update_attributes(order_place: index_of_first_element)

      true
    end
  end

  def locked?
    published?
  end

  def clone
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

    procedure.initiated_mail = initiated_mail.try(:dup)
    procedure.received_mail = received_mail.try(:dup)
    procedure.closed_mail = closed_mail.try(:dup)
    procedure.refused_mail = refused_mail.try(:dup)
    procedure.without_continuation_mail = without_continuation_mail.try(:dup)

    return procedure if procedure.save
  end

  def publish!(path)
    self.update_attributes!({ published_at: Time.now, archived_at: nil })
    ProcedurePath.create!(path: path, procedure: self, administrateur: self.administrateur)
  end

  def published?
    published_at.present?
  end

  def publiee?
    published_at.present? && archived_at.nil?
  end

  def archive
    self.update_attributes!(archived_at: Time.now)
  end

  def archivee?
    archived_at.present?
  end

  def total_dossier
    self.dossiers.state_not_brouillon.size
  end

  def generate_export
    exportable_dossiers = dossiers.downloadable

    headers = exportable_dossiers.any? ? exportable_dossiers.first.export_headers : []
    data = exportable_dossiers.any? ? exportable_dossiers.map { |d| d.full_data_strings_array } : [[]]

    {
      headers: headers,
      data: data
    }
  end

  def procedure_overview(start_date)
    ProcedureOverview.new(self, start_date)
  end

  def initiated_mail_template
    initiated_mail || Mails::InitiatedMail.default
  end

  def received_mail_template
    received_mail || Mails::ReceivedMail.default
  end

  def closed_mail_template
    closed_mail || Mails::ClosedMail.default
  end

  def refused_mail_template
    refused_mail || Mails::RefusedMail.default
  end

  def without_continuation_mail_template
    without_continuation_mail || Mails::WithoutContinuationMail.default
  end
end
