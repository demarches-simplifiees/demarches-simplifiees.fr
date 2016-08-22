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
           header_section: 'header_section'
       }

  belongs_to :procedure

  has_many :champ, dependent: :destroy
  has_one :drop_down_list

  accepts_nested_attributes_for :drop_down_list


  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :type_champ, presence: true, allow_blank: false, allow_nil: false
  # validates :order_place, presence: true, allow_blank: false, allow_nil: false
end