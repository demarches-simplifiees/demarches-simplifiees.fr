class Description < SimpleDelegator
  include Rails.application.routes.url_helpers

  attr_reader :type_de_champ_ids

  def initialize(procedure)
    super(procedure)
    @type_de_champ_ids = []
  end

  def update(attributes)
    @type_de_champ_ids = attributes[:type_de_champ_ids].presence || []
    @type_de_champ_ids << attributes[:type_de_champ_id_to_add] if attributes[:type_de_champ_id_to_add]
    @type_de_champ_ids = @type_de_champ_ids - [attributes[:type_de_champ_id_to_remove]] if attributes[:type_de_champ_id_to_remove]
  end

  def types_de_champ
    active_revision.types_de_champ_public
  end

  def include?(type_de_champ_id)
    @type_de_champ_ids.include?(type_de_champ_id.to_s)
  end

  def to_s # TODO: SEB limit length to 2000
    new_dossier_url({ procedure_id: id }.merge(prefilled_champs))
  end

  private

  def prefilled_champs
    types_de_champ.where(id: @type_de_champ_ids).map { |type_de_champ| ["champ_#{type_de_champ.to_typed_id}", type_de_champ.libelle] }.to_h
  end
end
