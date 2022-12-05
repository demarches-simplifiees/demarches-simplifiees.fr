class PrefillParams
  def initialize(dossier, params)
    @dossier = dossier
    @params = params
  end

  def to_a
    build_prefill_values.filter(&:prefillable?).map(&:to_h)
  end

  private

  def build_prefill_values
    value_by_stable_id = @params
      .to_unsafe_hash
      .map { |typed_id, value| [stable_id_from_typed_id(typed_id), value] }
      .filter { |stable_id, value| stable_id.present? && value.present? }
      .to_h

    @dossier
      .find_champs_by_stable_ids(value_by_stable_id.keys)
      .map { |champ| [champ, value_by_stable_id[champ.stable_id]] }
      .map { |champ, value| PrefillValue.new(champ:, value:) }
  end

  def stable_id_from_typed_id(typed_id)
    Champ.id_from_typed_id(typed_id).to_i
  rescue
    nil
  end

  class PrefillValue
    AUTHORIZED_TYPES_DE_CHAMPS = [
      TypeDeChamp.type_champs.fetch(:text),
      TypeDeChamp.type_champs.fetch(:textarea),
      TypeDeChamp.type_champs.fetch(:decimal_number),
      TypeDeChamp.type_champs.fetch(:integer_number),
      TypeDeChamp.type_champs.fetch(:email),
      TypeDeChamp.type_champs.fetch(:phone),
      TypeDeChamp.type_champs.fetch(:address),
      TypeDeChamp.type_champs.fetch(:pays),
      TypeDeChamp.type_champs.fetch(:regions),
      TypeDeChamp.type_champs.fetch(:departements),
      TypeDeChamp.type_champs.fetch(:siret),
      TypeDeChamp.type_champs.fetch(:rna),
      TypeDeChamp.type_champs.fetch(:iban),
      TypeDeChamp.type_champs.fetch(:annuaire_education)
    ]

    NEED_VALIDATION_TYPES_DE_CHAMPS = [
      TypeDeChamp.type_champs.fetch(:decimal_number),
      TypeDeChamp.type_champs.fetch(:integer_number)
    ]

    attr_reader :champ, :value

    def initialize(champ:, value:)
      @champ = champ
      @value = value
    end

    def prefillable?
      exists? && authorized? && valid?
    end

    def to_h
      {
        id: champ.id,
        value: value
      }
    end

    private

    def exists?
      champ.present?
    end

    def authorized?
      AUTHORIZED_TYPES_DE_CHAMPS.include?(champ.type_champ)
    end

    def valid?
      return true unless NEED_VALIDATION_TYPES_DE_CHAMPS.include?(champ.type_champ)

      champ.value = value
      champ.valid?
    end
  end
end
