class PrefillParams
  def initialize(dossier, params)
    @dossier = dossier
    @params = params
  end

  def to_a
    @params
      .to_unsafe_hash
      .map { |key, value| PrefillValue.new(@dossier, key, value) }
      .filter(&:prefillable?)
      .map(&:to_h)
  end

  private

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

    def initialize(dossier, typed_id, value)
      @champ = find_champ(dossier, typed_id)
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

    def find_champ(dossier, typed_id)
      stable_id = Champ.id_from_typed_id(typed_id) rescue nil
      return unless stable_id

      dossier.find_champ_by_stable_id(stable_id)
    end
  end
end
