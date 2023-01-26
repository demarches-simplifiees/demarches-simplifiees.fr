# == Schema Information
#
# Table name: champs
#
#  id                             :integer          not null, primary key
#  data                           :jsonb
#  fetch_external_data_exceptions :string           is an Array
#  prefilled                      :boolean          default(FALSE)
#  private                        :boolean          default(FALSE), not null
#  rebased_at                     :datetime
#  type                           :string
#  value                          :string
#  value_json                     :jsonb
#  created_at                     :datetime
#  updated_at                     :datetime
#  dossier_id                     :integer
#  etablissement_id               :integer
#  external_id                    :string
#  parent_id                      :bigint
#  row_id                         :string
#  type_de_champ_id               :integer
#
class Champ < ApplicationRecord
  include ChampConditionalConcern

  belongs_to :dossier, inverse_of: false, touch: true, optional: false
  belongs_to :type_de_champ, inverse_of: :champ, optional: false
  belongs_to :parent, class_name: 'Champ', optional: true
  has_many_attached :piece_justificative_file

  # We declare champ specific relationships (Champs::CarteChamp, Champs::SiretChamp and Champs::RepetitionChamp)
  # here because otherwise we can't easily use includes in our queries.
  has_many :geo_areas, -> { order(:created_at) }, dependent: :destroy, inverse_of: :champ
  belongs_to :etablissement, optional: true, dependent: :destroy
  has_many :champs, -> { ordered }, foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy

  delegate :procedure, to: :dossier

  delegate :libelle,
    :type_champ,
    :description,
    :drop_down_list_options,
    :drop_down_other?,
    :drop_down_list_options?,
    :drop_down_list_disabled_options,
    :drop_down_list_enabled_non_empty_options,
    :drop_down_secondary_libelle,
    :drop_down_secondary_description,
    :collapsible_explanation_enabled?,
    :collapsible_explanation_text,
    :exclude_from_export?,
    :exclude_from_view?,
    :repetition?,
    :block?,
    :dossier_link?,
    :titre_identite?,
    :header_section?,
    :simple_drop_down_list?,
    :linked_drop_down_list?,
    :non_fillable?,
    :fillable?,
    :cnaf?,
    :dgfip?,
    :pole_emploi?,
    :mesri?,
    :rna?,
    :siret?,
    :carte?,
    :stable_id,
    :mandatory?,
    :prefillable?,
    :refresh_after_update?,
    to: :type_de_champ

  delegate :revision, to: :dossier, prefix: true

  scope :updated_since?, -> (date) { where('champs.updated_at > ?', date) }
  scope :public_only, -> { where(private: false) }
  scope :private_only, -> { where(private: true) }
  scope :ordered, -> do
    includes(:type_de_champ)
      .joins(dossier: { revision: :revision_types_de_champ })
      .where('procedure_revision_types_de_champ.type_de_champ_id = champs.type_de_champ_id')
      .order(:row_id, :position)
  end
  scope :public_ordered, -> { public_only.ordered }
  scope :private_ordered, -> { private_only.ordered }
  scope :root, -> { where(parent_id: nil) }
  scope :prefilled, -> { where(prefilled: true) }

  before_create :set_dossier_id, if: :needs_dossier_id?
  before_validation :set_dossier_id, if: :needs_dossier_id?
  before_save :cleanup_if_empty
  before_save :normalize
  after_update_commit :fetch_external_data_later

  def public?
    !private?
  end

  def child?
    parent_id.present?
  end

  def sections
    @sections ||= dossier.sections_for(self)
  end

  # used for the `required` html attribute
  # check visibility to avoid hidden required input
  # which prevent the form from being sent.
  def required?
    type_de_champ.mandatory? && visible?
  end

  def mandatory_blank?
    mandatory? && blank?
  end

  def blank?
    value.blank?
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
    if row_id.present?
      GraphQL::Schema::UniqueWithinType.encode('Champ', "#{stable_id}|#{row_id}")
    else
      type_de_champ.to_typed_id
    end
  end

  def self.decode_typed_id(typed_id)
    _, stable_id_with_maybe_row = GraphQL::Schema::UniqueWithinType.decode(typed_id)
    stable_id_with_maybe_row.split('|')
  end

  def html_label?
    true
  end

  def input_group_id
    "champ-#{html_id}"
  end

  def input_id
    "#{html_id}-input"
  end

  # A predictable string to use when generating an input name for this champ.
  #
  # Rail's FormBuilder can auto-generate input names, using the form "dossier[champs_public_attributes][5]",
  # where [5] is the index of the field in the form.
  # However the field index makes it difficult to render a single field, independent from the ordering of the others.
  #
  # Luckily, this is only used to make the name unique, but the actual value is ignored when Rails parses nested
  # attributes. So instead of the field index, this method uses the champ id; which gives us an independent and
  # predictable input name.
  def input_name
    if private?
      "dossier[champs_private_attributes][#{id}]"
    else
      "dossier[champs_public_attributes][#{id}]"
    end
  end

  def labelledby_id
    "#{html_id}-label"
  end

  def describedby_id
    "#{html_id}-description" if description.present?
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

  def clone
    champ_attributes = [:parent_id, :private, :row_id, :type, :type_de_champ_id]
    value_attributes = private? ? [] : [:value, :value_json, :data, :external_id]
    relationships = private? ? [] : [:etablissement, :geo_areas]

    deep_clone(only: champ_attributes + value_attributes, include: relationships) do |original, kopy|
      PiecesJustificativesService.clone_attachments(original, kopy)
    end
  end

  private

  def html_id
    "#{stable_id}-#{id}"
  end

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
      ChampFetchExternalDataJob.perform_later(self, external_id)
    end
  end

  def normalize
    return if value.nil?
    return if value.present? && !value.include?("\u0000")

    self.value = value.delete("\u0000")
  end

  class NotImplemented < ::StandardError
    def initialize(method)
      super(":#{method} not implemented")
    end
  end
end
