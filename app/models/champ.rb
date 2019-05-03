class Champ < ApplicationRecord
  belongs_to :dossier, touch: true
  belongs_to :type_de_champ, inverse_of: :champ
  belongs_to :parent, class_name: 'Champ'
  has_many :commentaires
  has_one_attached :piece_justificative_file

  # We declare champ specific relationships (Champs::CarteChamp and Champs::SiretChamp)
  # here because otherwise we can't easily use includes in our queries.
  has_many :geo_areas, dependent: :destroy
  belongs_to :etablissement, dependent: :destroy

  delegate :libelle, :type_champ, :order_place, :mandatory?, :description, :drop_down_list, :exclude_from_export?, :exclude_from_view?, :repetition?, to: :type_de_champ

  scope :updated_since?, -> (date) { where('champs.updated_at > ?', date) }
  scope :public_only, -> { where(private: false) }
  scope :private_only, -> { where(private: true) }
  scope :ordered, -> { includes(:type_de_champ).order(:row, 'types_de_champ.order_place') }
  scope :root, -> { where(parent_id: nil) }

  before_create :set_dossier_id, if: :needs_dossier_id?

  def public?
    !private?
  end

  def mandatory_and_blank?
    mandatory? && blank?
  end

  def blank?
    case type_de_champ.type_champ
    when TypeDeChamp.type_champs.fetch(:carte)
      value.blank? || value == '[]'
    else
      value.blank?
    end
  end

  def search_terms
    [to_s]
  end

  def to_s
    value.present? ? value.to_s : ''
  end

  def for_export
    value.presence
  end

  def for_api
    value
  end

  def main_value_name
    :value
  end

  private

  def needs_dossier_id?
    !dossier_id && parent_id
  end

  def set_dossier_id
    self.dossier_id = parent.dossier_id
  end
end
