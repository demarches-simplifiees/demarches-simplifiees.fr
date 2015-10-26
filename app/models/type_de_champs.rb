class TypeDeChamps < ActiveRecord::Base
  enum type: {text: 'text',
              textarea: 'textarea',
              datetime: 'datetime',
              number: 'number'
       }

  belongs_to :procedure

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :type, presence: true, allow_blank: false, allow_nil: false
  validates :order_place, presence: true, allow_blank: false, allow_nil: false
end