class PrefillDescription < SimpleDelegator
  include Rails.application.routes.url_helpers

  MAX_PREFILL_LINK_LENGTH = 2000

  attr_reader :selected_type_de_champ_ids

  def initialize(procedure)
    super(procedure)
    @selected_type_de_champ_ids = []
  end

  def update(attributes)
    @selected_type_de_champ_ids = attributes[:selected_type_de_champ_ids]&.split(' ') || []
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

  def active_fillable_public_types_de_champ
    active_revision.types_de_champ_public.fillable
  end

  def prefilled_champs_for_link
    prefilled_champs_as_params.map(&:to_a).to_h
  end

  def prefilled_champs_for_query
    prefilled_champs_as_params.map(&:to_s).join(', ')
  end

  def prefilled_champs_as_params
    prefilled_champs.map { |type_de_champ| Param.new(type_de_champ.to_typed_id, type_de_champ.example_value) }
  end

  Param = Struct.new(:key, :value) do
    def to_a
      ["champ_#{key}", value]
    end

    def to_s
      if value.is_a?(Array)
        "\"champ_#{key}\": #{value}"
      else
        "\"champ_#{key}\": \"#{value}\""
      end
    end
  end
end
