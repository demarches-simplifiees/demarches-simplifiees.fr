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
    active_revision.types_de_champ_public
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

  def prefilled_champs
    @prefilled_champs ||= types_de_champ.where(id: selected_type_de_champ_ids)
  end

  private

  def prefilled_champs_for_link
    prefilled_champs.map { |type_de_champ| ["champ_#{type_de_champ.to_typed_id}", example_value(type_de_champ)] }.to_h
  end

  def prefilled_champs_for_query
    prefilled_champs.map { |type_de_champ| "\"champ_#{type_de_champ.to_typed_id}\": \"#{example_value(type_de_champ)}\"" } .join(', ')
  end

  def example_value(type_de_champ)
    I18n.t("views.prefill_descriptions.edit.examples.#{type_de_champ.type_champ}")
  end
end
