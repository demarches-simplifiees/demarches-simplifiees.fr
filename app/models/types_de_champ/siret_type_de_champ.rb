# frozen_string_literal: true

class TypesDeChamp::SiretTypeDeChamp < TypesDeChamp::TypeDeChampBase
  include AddressableColumnConcern

  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def champ_blank_or_invalid?(champ) = Siret.new(siret: champ.value).invalid?

  def columns(procedure:, displayable: true, prefix: nil)
    super.concat(addressable_columns(procedure:, displayable:, prefix:))
  end
end
