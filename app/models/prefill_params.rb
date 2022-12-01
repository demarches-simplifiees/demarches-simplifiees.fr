class PrefillParams
  def initialize(dossier, params)
    @dossier = dossier
    @params = params
  end

  def to_a
    # Builds: [{ stable_id: 1, value: "a value" }, { stable_id: 2, value: "another value"}]
    stable_ids_and_values = convert_typed_ids_to_stable_ids

    # Builds: [{stable_id: "1", champ: #<Champs::...>}, {stable_id: "2", champ: #<Champs::...>}]
    stable_ids_and_champs = find_champs(stable_ids_and_values.map { _1[:stable_id] })

    # Merges the arrays together, filters out the values we don't want and returns [{ id: champ_1_id, value: value_1}, ...]
    merge_by_stable_ids(stable_ids_and_values + stable_ids_and_champs)
      .map { PrefillValue.new(champ: _1[:champ], value: _1[:value]) }
      .filter(&:prefillable?)
      .map(&:to_h)
  end

  private

  def convert_typed_ids_to_stable_ids
    @params
      .to_unsafe_hash
      .map { |typed_id, value| { stable_id: stable_id_from_typed_id(typed_id), value: value } }
      .filter { _1[:stable_id].present? && _1[:value].present? }
  end

  def find_champs(stable_ids)
    @dossier
      .find_champs_by_stable_ids(stable_ids)
      .map { |champ| { stable_id: champ.stable_id.to_s, champ: champ } }
  end

  def merge_by_stable_ids(arrays_of_hashes_with_stable_id)
    arrays_of_hashes_with_stable_id
      .group_by { _1[:stable_id] }
      .values
      .map { _1.reduce(:merge) }
  end

  def stable_id_from_typed_id(typed_id)
    Champ.id_from_typed_id(typed_id)
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
