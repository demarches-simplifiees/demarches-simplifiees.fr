# frozen_string_literal: true

class Champ < ApplicationRecord
  include ChampConditionalConcern
  include ChampsValidateConcern

  self.ignored_columns += [:type_de_champ_id, :parent_id]

  attr_readonly :stable_id

  belongs_to :dossier, inverse_of: false, touch: true, optional: false
  has_many_attached :piece_justificative_file

  # We declare champ specific relationships (Champs::CarteChamp, Champs::SiretChamp and Champs::RepetitionChamp)
  # here because otherwise we can't easily use includes in our queries.
  has_many :geo_areas, -> { order(:created_at) }, dependent: :destroy, inverse_of: :champ
  belongs_to :etablissement, optional: true, dependent: :destroy

  delegate :procedure, to: :dossier

  def type_de_champ
    @type_de_champ ||= dossier.revision
      .types_de_champ
      .find(-> { raise "Type De Champ #{stable_id} not found in Revision #{dossier.revision_id}" }) { _1.stable_id == stable_id }
  end

  delegate :libelle,
    :type_champ,
    :description,
    :drop_down_options,
    :drop_down_other?,
    :drop_down_options_with_other,
    :drop_down_secondary_libelle,
    :drop_down_secondary_description,
    :collapsible_explanation_enabled?,
    :collapsible_explanation_text,
    :header_section_level_value,
    :current_section_level,
    :exclude_from_export?,
    :exclude_from_view?,
    :repetition?,
    :block?,
    :dossier_link?,
    :departement?,
    :region?,
    :textarea?,
    :piece_justificative?,
    :titre_identite?,
    :header_section?,
    :checkbox?,
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
    :datetime?,
    :mandatory?,
    :prefillable?,
    :refresh_after_update?,
    :character_limit?,
    :character_limit,
    :yes_no?,
    :expression_reguliere,
    :expression_reguliere_exemple_text,
    :expression_reguliere_error_message,
    to: :type_de_champ

  delegate :to_typed_id, :to_typed_id_for_query, to: :type_de_champ, prefix: true

  delegate :revision, to: :dossier, prefix: true
  delegate :used_by_routing_rules?, to: :type_de_champ

  scope :updated_since?, -> (date) { where('champs.updated_at > ?', date) }
  scope :prefilled, -> { where(prefilled: true) }

  before_save :cleanup_if_empty
  before_save :normalize
  after_update_commit :fetch_external_data_later

  def public?
    !private?
  end

  def child?
    row_id.present?
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
    TypeDeChamp.champ_value(type_champ, self)
  end

  def for_api
    TypeDeChamp.champ_value_for_api(type_champ, self, 1)
  end

  def for_api_v2
    TypeDeChamp.champ_value_for_api(type_champ, self, 2)
  end

  def for_export(path = :value)
    TypeDeChamp.champ_value_for_export(type_champ, self, path)
  end

  def for_tag(path = :value)
    TypeDeChamp.champ_value_for_tag(type_champ, self, path)
  end

  def main_value_name
    :value
  end

  def champ_descriptor_id
    type_de_champ.to_typed_id
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

  def legend_label?
    false
  end

  def single_checkbox?
    false
  end

  def input_group_id
    html_id
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
  # attributes. So instead of the field index, this method uses the champ public_id; which gives us an independent and
  # predictable input name.
  def input_name
    if private?
      "dossier[champs_private_attributes][#{public_id}]"
    else
      "dossier[champs_public_attributes][#{public_id}]"
    end
  end

  def labelledby_id
    "#{html_id}-label"
  end

  def describedby_id
    "#{html_id}-describedby_id"
  end

  def log_fetch_external_data_exception(exception)
    update_column(:fetch_external_data_exceptions, [exception.inspect])
  end

  def fetch_external_data?
    false
  end

  def poll_external_data?
    false
  end

  def fetch_external_data_error?
    fetch_external_data_exceptions.present? && self.external_id.present?
  end

  def fetch_external_data_pending?
    fetch_external_data? && poll_external_data? && external_id.present? && data.nil? && !fetch_external_data_error?
  end

  def fetch_external_data
    raise NotImplemented.new(:fetch_external_data)
  end

  def update_with_external_data!(data:)
    update!(data: data)
  end

  def clone(fork = false)
    champ_attributes = [:private, :row_id, :type, :stable_id, :stream]
    value_attributes = fork || !private? ? [:value, :value_json, :data, :external_id] : []
    relationships = fork || !private? ? [:etablissement, :geo_areas] : []

    deep_clone(only: champ_attributes + value_attributes, include: relationships, validate: !fork) do |original, kopy|
      if original.is_a?(Champ)
        kopy.write_attribute(:stable_id, original.stable_id)
        kopy.write_attribute(:stream, 'main')
      end
      ClonePiecesJustificativesService.clone_attachments(original, kopy) if fork || !private?
    end
  end

  def focusable_input_id
    input_id
  end

  def forked_with_changes?
    public? && dossier.champ_forked_with_changes?(self)
  end

  def public_id
    if row_id.blank?
      stable_id.to_s
    else
      "#{stable_id}-#{row_id}"
    end
  end

  def html_id
    type_de_champ.html_id(row_id)
  end

  def cleanup_if_empty
    if fetch_external_data? && persisted? && external_id_changed?
      self.data = nil
    end
  end

  def fetch_external_data_later
    if fetch_external_data? && external_id.present? && data.nil?
      update_column(:fetch_external_data_exceptions, [])
      ChampFetchExternalDataJob.perform_later(self, external_id)
    end
  end

  def normalize
    return if value.nil?
    return if value.present? && !value.include?("\u0000")

    write_attribute(:value, value.delete("\u0000"))
  end

  class NotImplemented < ::StandardError
    def initialize(method)
      super(":#{method} not implemented")
    end
  end
end
