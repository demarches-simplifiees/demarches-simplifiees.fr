class Champ < ApplicationRecord
  belongs_to :dossier, touch: true
  belongs_to :type_de_champ, inverse_of: :champ
  has_many :commentaires
  has_one_attached :piece_justificative_file
  has_one :virus_scan

  # We declare champ specific relationships (Champs::CarteChamp and Champs::SiretChamp)
  # here because otherwise we can't easily use includes in our queries.
  has_many :geo_areas, dependent: :destroy
  belongs_to :etablissement, dependent: :destroy

  delegate :libelle, :type_champ, :order_place, :mandatory?, :description, :drop_down_list, to: :type_de_champ

  scope :updated_since?, -> (date) { where('champs.updated_at > ?', date) }
  scope :public_only, -> { where(private: false) }
  scope :private_only, -> { where(private: true) }
  scope :ordered, -> { includes(:type_de_champ).order('types_de_champ.order_place') }

  def public?
    !private?
  end

  def mandatory_and_blank?
    if mandatory?
      case type_de_champ.type_champ
      when TypeDeChamp.type_champs.fetch(:carte)
        value.blank? || value == '[]'
      else
        value.blank?
      end
    else
      false
    end
  end

  def search_terms
    [ to_s ]
  end

  def to_s
    if value.present?
      string_value
    else
      ''
    end
  end

  def for_export
    if value.present?
      value_for_export
    else
      nil
    end
  end

  def main_value_name
    :value
  end

  private

  def string_value
    value.to_s
  end

  def value_for_export
    value
  end
end
