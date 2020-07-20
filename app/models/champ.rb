class Champ < ApplicationRecord
  belongs_to :dossier, -> { with_discarded }, inverse_of: :champs, touch: true
  belongs_to :type_de_champ, inverse_of: :champ
  belongs_to :parent, class_name: 'Champ', optional: true
  has_many :commentaires
  has_one_attached :piece_justificative_file

  # We declare champ specific relationships (Champs::CarteChamp, Champs::SiretChamp and Champs::RepetitionChamp)
  # here because otherwise we can't easily use includes in our queries.
  has_many :geo_areas, dependent: :destroy
  belongs_to :etablissement, optional: true, dependent: :destroy
  has_many :champs, -> { ordered }, foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy

  delegate :libelle,
    :type_champ,
    :procedure,
    :order_place,
    :mandatory?,
    :description,
    :drop_down_list_options,
    :drop_down_list_options?,
    :drop_down_list_disabled_options,
    :drop_down_list_enabled_non_empty_options,
    :exclude_from_export?,
    :exclude_from_view?,
    :repetition?,
    :dossier_link?,
    to: :type_de_champ

  scope :updated_since?, -> (date) { where('champs.updated_at > ?', date) }
  scope :public_only, -> { where(private: false) }
  scope :private_only, -> { where(private: true) }
  scope :ordered, -> { includes(:type_de_champ).order(:row, 'types_de_champ.order_place') }
  scope :root, -> { where(parent_id: nil) }

  before_create :set_dossier_id, if: :needs_dossier_id?

  validates :type_de_champ_id, uniqueness: { scope: [:dossier_id, :row] }

  def public?
    !private?
  end

  def siblings
    if parent
      parent&.champs
    elsif public?
      dossier&.champs
    else
      dossier&.champs_private
    end
  end

  def mandatory_and_blank?
    mandatory? && blank?
  end

  def blank?
    case type_de_champ.type_champ
    when TypeDeChamp.type_champs.fetch(:carte)
      geo_areas.blank? || value == '[]'
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

  def for_api_v2
    to_s
  end

  def for_tag
    value.present? ? value.to_s : ''
  end

  def main_value_name
    :value
  end

  def to_typed_id
    type_de_champ.to_typed_id
  end

  def html_label?
    true
  end

  def stable_id
    type_de_champ.stable_id
  end

  private

  def needs_dossier_id?
    !dossier_id && parent_id
  end

  def set_dossier_id
    self.dossier_id = parent.dossier_id
  end
end
