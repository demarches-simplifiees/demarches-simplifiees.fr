class Procedure < ActiveRecord::Base
  has_many :types_de_piece_justificative, dependent: :destroy
  has_many :types_de_champ, class_name: 'TypeDeChampPublic', dependent: :destroy
  has_many :types_de_champ_private, dependent: :destroy
  has_many :dossiers
  has_many :mail_templates

  has_one :initiated_mail

  has_one :procedure_path, dependent: :destroy

  has_one :module_api_carto, dependent: :destroy

  belongs_to :administrateur

  has_many :assign_to, dependent: :destroy
  has_many :gestionnaires, through: :assign_to

  has_many :preference_list_dossiers

  delegate :use_api_carto, to: :module_api_carto

  accepts_nested_attributes_for :types_de_champ, :reject_if => proc { |attributes| attributes['libelle'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :types_de_piece_justificative, :reject_if => proc { |attributes| attributes['libelle'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :module_api_carto
  accepts_nested_attributes_for :types_de_champ_private

  mount_uploader :logo, ProcedureLogoUploader

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :description, presence: true, allow_blank: false, allow_nil: false

  def initiated_mail_with_override
    initiated_mail_without_override || InitiatedMail.default
  end
  alias_method_chain :initiated_mail, :override

  def path
    procedure_path.path unless procedure_path.nil?
  end

  def default_path
    libelle.downcase.gsub(/[^a-z0-9\-_]/, "_").gsub(/_*$/, '').gsub(/_+/, '_')
  end

  def types_de_champ_ordered
    types_de_champ.order(:order_place)
  end

  def types_de_champ_private_ordered
    types_de_champ_private.order(:order_place)
  end

  def types_de_piece_justificative_ordered
    types_de_piece_justificative.order(:order_place)
  end

  def self.not_archived id
    Procedure.where(archived: false).find(id)
  end

  def self.active id
    Procedure.where(archived: false, published: true).find(id)
  end

  def switch_types_de_champ index_of_first_element
    switch_list_order(types_de_champ_ordered, index_of_first_element)
  end

  def switch_types_de_champ_private index_of_first_element
    switch_list_order(types_de_champ_private_ordered, index_of_first_element)
  end

  def switch_types_de_piece_justificative index_of_first_element
    switch_list_order(types_de_piece_justificative_ordered, index_of_first_element)
  end

  def switch_list_order(list, index_of_first_element)
    return false if index_of_first_element < 0
    return false if index_of_first_element == list.count - 1
    return false if list.count < 1
    list[index_of_first_element].update_attributes(order_place: index_of_first_element + 1)
    list[index_of_first_element + 1].update_attributes(order_place: index_of_first_element)
    true
  end

  def locked?
    published?
  end

  def clone
    procedure = self.deep_clone(include: [:types_de_piece_justificative, :types_de_champ, :types_de_champ_private, :module_api_carto, :mail_templates, types_de_champ: [:drop_down_list]])
    procedure.archived = false
    procedure.published = false
    procedure.logo_secure_token = nil
    procedure.remote_logo_url = self.logo_url
    return procedure if procedure.save
  end

  def publish!(path)
    self.update_attributes!({published: true, archived: false})
    ProcedurePath.create!(path: path, procedure: self, administrateur: self.administrateur)
  end

  def archive
    self.update_attributes!({archived: true})
  end

  def total_dossier
    self.dossiers.where.not(state: :draft).size
  end

end
