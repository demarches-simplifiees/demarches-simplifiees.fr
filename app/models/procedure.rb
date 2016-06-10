class Procedure < ActiveRecord::Base
  has_many :types_de_piece_justificative, dependent: :destroy
  has_many :types_de_champ, dependent: :destroy
  has_many :dossiers, dependent: :destroy

  has_one :module_api_carto, dependent: :destroy

  belongs_to :administrateur

  has_many :assign_to
  has_many :gestionnaires, through: :assign_to

  delegate :use_api_carto, to: :module_api_carto

  accepts_nested_attributes_for :types_de_champ,:reject_if => proc { |attributes| attributes['libelle'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :types_de_piece_justificative, :reject_if => proc { |attributes| attributes['libelle'].blank? }, :allow_destroy => true
  accepts_nested_attributes_for :module_api_carto

  mount_uploader :logo, ProcedureLogoUploader

  validates :libelle, presence: true, allow_blank: false, allow_nil: false
  validates :description, presence: true, allow_blank: false, allow_nil: false

  def types_de_champ_ordered
    types_de_champ.order(:order_place)
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

end
