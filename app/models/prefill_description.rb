class PrefillDescription < SimpleDelegator
  include Rails.application.routes.url_helpers

  MAX_PREFILL_LINK_LENGTH = 2000

  attr_reader :selected_type_de_champ_ids
  attr_reader :identity_items_selected

  def initialize(procedure)
    super(procedure)
    @selected_type_de_champ_ids = []
    @identity_items_selected = []
  end

  def update(attributes)
    @selected_type_de_champ_ids = attributes[:selected_type_de_champ_ids]&.split(' ') || []
    @identity_items_selected = attributes[:identity_items_selected]&.split(' ') || []
  end

  def types_de_champ
    TypesDeChamp::PrefillTypeDeChamp.wrap(active_revision.types_de_champ_public.fillable.partition(&:prefillable?).flatten, active_revision)
  end

  def include?(entity)
    selected_type_de_champ_ids.include?(entity) || identity_items_selected.include?(entity)
  end

  def link_too_long?
    prefill_link.length > MAX_PREFILL_LINK_LENGTH
  end

  def prefill_link
    @prefill_link ||= CGI.unescape(commencer_url({ path: path }.merge(prefilled_champs_as_params).merge(prefilled_identity_as_params)))
  end

  def prefill_query
    @prefill_query ||=
      <<~TEXT
        curl --request POST '#{api_public_v1_dossiers_url(self)}' \\
             --header 'Content-Type: application/json' \\
             --data '#{prefilled_identity_as_params.merge(prefilled_champs_as_params).to_json}'
      TEXT
  end

  def prefilled_champs
    @prefilled_champs ||= TypesDeChamp::PrefillTypeDeChamp.wrap(active_fillable_public_types_de_champ.where(id: selected_type_de_champ_ids), active_revision)
  end

  private

  def active_fillable_public_types_de_champ
    active_revision.types_de_champ_public.fillable
  end

  def prefilled_champs_as_params
    prefilled_champs.map { |type_de_champ| ["champ_#{type_de_champ.to_typed_id_for_query}", type_de_champ.example_value] }.to_h
  end

  def prefilled_identity_as_params
    identity_items_selected.map { |item| ["identite_#{item}", I18n.t("views.prefill_descriptions.edit.examples.#{item}")] }.to_h
  end
end
