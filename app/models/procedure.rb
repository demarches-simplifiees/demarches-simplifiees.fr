class Procedure < ActiveRecord::Base
  has_many :types_de_piece_justificative, -> { order "order_place ASC" }, dependent: :destroy
  has_many :types_de_champ, class_name: 'TypeDeChampPublic', dependent: :destroy
  has_many :types_de_champ_private, dependent: :destroy
  has_many :dossiers

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

  # for all those mails do
  # has_one :initiated_mail, class_name: 'Mails::InitiatedMail'
  #
  # add a method to return default mail if none is saved
  # def initiated_mail_with_override
  #   self.initiated_mail_without_override || InitiatedMail.default
  # end
  # alias_method_chain :initiated_mail, :override

  MAIL_TEMPLATE_TYPES = %w(InitiatedMail ReceivedMail ClosedMail RefusedMail WithoutContinuationMail)

  MAIL_TEMPLATE_TYPES.each do |name|
    has_one "#{name.underscore}".to_sym, class_name: "Mails::#{name}", dependent: :destroy
    define_method("#{name.underscore}_with_override") do
      self.send("#{name.underscore}_without_override") || Object.const_get("Mails::#{name}").default
    end
    alias_method_chain "#{name.underscore.to_sym}".to_s, :override
  end

  scope :not_archived, -> { where(archived: false) }

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
    Procedure.where(archived: false, published: true).find(id)
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
    procedure = self.deep_clone(include:
      [:types_de_piece_justificative,
        :types_de_champ,
        :types_de_champ_private,
        :module_api_carto,
        types_de_champ: [:drop_down_list]
      ])
    procedure.archived = false
    procedure.published = false
    procedure.logo_secure_token = nil
    procedure.remote_logo_url = self.logo_url

    MAIL_TEMPLATE_TYPES.each do |mtt|
      procedure.send("#{mtt.underscore}=", self.send("#{mtt.underscore}_without_override").try(:dup))
    end

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

  def generate_export
    exportable_dossiers = dossiers.downloadable

    headers = exportable_dossiers.any? ? exportable_dossiers.first.export_headers : []
    data = exportable_dossiers.any? ? exportable_dossiers.map { |d| d.full_data_strings_array } : [[]]

    {
      headers: headers,
      data: data
    }
  end

end
