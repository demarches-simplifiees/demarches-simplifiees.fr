# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  private                        :boolean          default(FALSE), not null
#  row                            :integer
#  type                           :string
#  value                          :string
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  type_de_champ_id               :integer
#
class Champ < ApplicationRecord
  belongs_to :dossier, -> { with_discarded }, inverse_of: :champs, touch: true, optional: false
  belongs_to :type_de_champ, inverse_of: :champ, optional: false
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
    :titre_identite?,
    to: :type_de_champ

  scope :updated_since?, -> (date) { where('champs.updated_at > ?', date) }
  scope :public_only, -> { where(private: false) }
  scope :private_only, -> { where(private: true) }
  scope :ordered, -> { includes(:type_de_champ).order(:row, 'types_de_champ.order_place') }
  scope :public_ordered, -> { public_only.joins(dossier: { revision: :revision_types_de_champ }).where('procedure_revision_types_de_champ.type_de_champ_id = champs.type_de_champ_id').order(:position) }
  # we need to do private champs order as manual join to avoid conflicting join names
  scope :private_ordered, -> do
    private_only.joins('
      INNER JOIN dossiers dossiers_private on dossiers_private.id = champs.dossier_id
      INNER JOIN types_de_champ types_de_champ_private on types_de_champ_private.id = champs.type_de_champ_id
      INNER JOIN procedure_revision_types_de_champ procedure_revision_types_de_champ_private
      ON procedure_revision_types_de_champ_private.revision_id = dossiers_private.revision_id')
      .where('procedure_revision_types_de_champ_private.type_de_champ_id = champs.type_de_champ_id')
      .order(:position)
  end

  scope :root, -> { where(parent_id: nil) }

  before_create :set_dossier_id, if: :needs_dossier_id?
  before_validation :set_dossier_id, if: :needs_dossier_id?
  before_save :cleanup_if_empty
  after_update_commit :fetch_external_data_later

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
    value.present? ? value.to_s.gsub(/ (\S{15})/, ' \1') : ''
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

  def log_fetch_external_data_exception(exception)
    exceptions = self.fetch_external_data_exceptions ||= []
    exceptions << exception.inspect
    update_column(:fetch_external_data_exceptions, exceptions)
  end

  def fetch_external_data?
    false
  end

  def fetch_external_data
    raise NotImplemented.new(:fetch_external_data)
  end

  private

  def needs_dossier_id?
    !dossier_id && parent_id
  end

  def set_dossier_id
    self.dossier_id = parent.dossier_id
  end

  def cleanup_if_empty
    if external_id_changed?
      self.data = nil
    end
  end

  def fetch_external_data_later
    if fetch_external_data? && external_id.present? && data.nil?
      ChampFetchExternalDataJob.perform_later(self)
    end
  end

  class NotImplemented < ::StandardError
    def initialize(method)
      super(":#{method} not implemented")
    end
  end
end
