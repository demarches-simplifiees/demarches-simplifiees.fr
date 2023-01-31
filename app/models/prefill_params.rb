class PrefillParams
  def initialize(dossier, params)
    @dossier = dossier
    @params = params
  end

  def to_a
    build_prefill_values.filter(&:prefillable?).map(&:to_h).flatten
  end

  private

  def build_prefill_values
    byebug
    # nop : "[{\"txt\":\"Texte court\", \"nb\":\"3.14\", \"Test dropdown\":\"Premier choix\", \"régio\":\"53\"}, {\"txt\":\"Texte court\", \"nb\":\"3.14\", \"Test dropdown\":\"Premier choix\", \"régio\":\"53\"}]"
    # {"champ_Q2hhbXAtNDI="=>["{\"txt\":\"abc\", \"nb\":\"1,12\"}", "{\"txt\":\"def\", \"nb\":\"2,12\"}"]}
    value_by_stable_id = @params
      .map { |prefixed_typed_id, value| [stable_id_from_typed_id(prefixed_typed_id), value] }
      .filter { |stable_id, value| stable_id.present? && value.present? }
      .to_h

    @dossier
      .find_champs_by_stable_ids(value_by_stable_id.keys)
      .map { |champ| [champ, value_by_stable_id[champ.stable_id]] }
      .map { |champ, value| PrefillValue.new(champ:, value:) }
  end

  def stable_id_from_typed_id(prefixed_typed_id)
    return nil unless prefixed_typed_id.starts_with?("champ_")

    Champ.id_from_typed_id(prefixed_typed_id.gsub("champ_", "")).to_i
  rescue
    nil
  end

  class PrefillValue
    NEED_VALIDATION_TYPES_DE_CHAMPS = [
      TypeDeChamp.type_champs.fetch(:decimal_number),
      TypeDeChamp.type_champs.fetch(:integer_number),
      TypeDeChamp.type_champs.fetch(:date),
      TypeDeChamp.type_champs.fetch(:datetime),
      TypeDeChamp.type_champs.fetch(:civilite),
      TypeDeChamp.type_champs.fetch(:yes_no),
      TypeDeChamp.type_champs.fetch(:checkbox),
      TypeDeChamp.type_champs.fetch(:pays),
      TypeDeChamp.type_champs.fetch(:regions)
    ]

    attr_reader :champ, :value

    def initialize(champ:, value:)
      @champ = champ
      @value = value
    end

    def prefillable?
      champ.prefillable? && valid?
    end

    def to_h
      if champ.type_champ == TypeDeChamp.type_champs.fetch(:repetition)
        repeatable_hashes
      else
        {
          id: champ.id,
          value: value
        }
      end
    end

    private

    def valid?
      return true unless NEED_VALIDATION_TYPES_DE_CHAMPS.include?(champ.type_champ)

      champ.value = value
      champ.valid?(:prefill)
    end

    def repeatable_hashes
      value.map.with_index do |repetition, index|
        row = champ.rows[index] || champ.add_row(champ.dossier_revision)
        JSON.parse(repetition).map do |key, value|
          id = row.find { |champ| champ.libelle == key }&.id
          next unless id
          { id: id, value: value }
        end
      rescue JSON::ParserError
      end.compact
    end
  end
end
