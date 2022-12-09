class Description < SimpleDelegator
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

  def too_long?
    prefill_link.length > MAX_PREFILL_LINK_LENGTH
  end

  def prefill_link
    commencer_path({ path: path }.merge(prefilled_champs))
  end

  private

  def prefilled_champs
    types_de_champ.where(id: selected_type_de_champ_ids).map { |type_de_champ| ["champ_#{type_de_champ.to_typed_id}", type_de_champ.libelle] }.to_h
  end
end
