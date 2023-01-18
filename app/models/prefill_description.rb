class PrefillDescription < SimpleDelegator
  include Rails.application.routes.url_helpers

  MAX_PREFILL_LINK_LENGTH = 2000

  attr_reader :selected_type_de_champ_ids

  def initialize(procedure)
    super(procedure)
    @selected_type_de_champ_ids = []
  end

  def update(attributes)
    @selected_type_de_champ_ids = attributes[:selected_type_de_champ_ids].presence || []
  end

  def types_de_champ
    TypesDeChamp::PrefillTypeDeChamp.wrap(active_revision.types_de_champ_public.fillable.partition(&:prefillable?).flatten)
  end

  def include?(type_de_champ_id)
    selected_type_de_champ_ids.include?(type_de_champ_id.to_s)
  end

  def link_too_long?
    prefill_link.length > MAX_PREFILL_LINK_LENGTH
  end

  def prefill_link
    @prefill_link ||= commencer_url({ path: path }.merge(prefilled_champs_for_link))
  end

  def prefill_query
    @prefill_query ||=
      <<~TEXT
        curl --request POST '#{api_public_v1_dossiers_url(self)}' \\
             --header 'Content-Type: application/json' \\
             --data '{#{prefilled_champs_for_query}}'
      TEXT
  end

  def prefilled_champs
    @prefilled_champs ||= TypesDeChamp::PrefillTypeDeChamp.wrap(active_fillable_public_types_de_champ.where(id: selected_type_de_champ_ids))
  end

  private

  def prefilled_champs_for_link
    prefilled_champs.map { |type_de_champ| ["champ_#{type_de_champ.to_typed_id}", type_de_champ.example_value] }.to_h
  end

  def prefilled_champs_for_query
    prefilled_champs.map { |type_de_champ| "\"champ_#{type_de_champ.to_typed_id}\": \"#{type_de_champ.example_value}\"" } .join(', ')
  end

  def active_fillable_public_types_de_champ
    active_revision.types_de_champ_public.fillable
  end
end
