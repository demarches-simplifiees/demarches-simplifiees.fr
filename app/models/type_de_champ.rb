class TypeDeChamp < ActiveRecord::Base
  enum type_champs: {
    text: 'text',
    textarea: 'textarea',
    date: 'date',
    datetime: 'datetime',
    number: 'number',
    checkbox: 'checkbox',
    civilite: 'civilite',
    email: 'email',
    phone: 'phone',
    address: 'address',
    yes_no: 'yes_no',
    drop_down_list: 'drop_down_list',
    multiple_drop_down_list: 'multiple_drop_down_list',
    pays: 'pays',
    regions: 'regions',
    departements: 'departements',
    engagement: 'engagement',
    header_section: 'header_section',
    explication: 'explication',
    dossier_link: 'dossier_link'
  }

  belongs_to :procedure

  has_many :champ, dependent: :destroy
  has_one :drop_down_list

  accepts_nested_attributes_for :drop_down_list

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :type_champ, presence: true, allow_blank: false, allow_nil: false

  before_validation :check_mandatory

  def self.type_de_champs_list_fr
    type_champs.map { |champ| [I18n.t("activerecord.attributes.type_de_champ.type_champs.#{champ.last}"), champ.first] }
  end

  def field_for_list?
    !type_champ.in? ['textarea', 'header_section']
  end

  def check_mandatory
    if type_champ.in? ['header_section', 'explication']
      self.mandatory = false
    end
    true
  end
end
