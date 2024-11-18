# frozen_string_literal: true

class TypesDeChamp::RNATypeDeChamp < TypesDeChamp::TypeDeChampBase
  include AddressableColumnConcern

  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def champ_value_for_export(champ, path = :value)
    champ.identifier
  end

  def columns(procedure:, displayable: true, prefix: nil)
    super
      .concat(addressable_columns(procedure:, displayable:, prefix:))
      .concat([
        Columns::JSONPathColumn.new(
          procedure_id: procedure.id,
          stable_id:,
          tdc_type: type_champ,
          label: "#{libelle_with_prefix(prefix)} – Titre au répertoire national des associations",
          type: :text,
          jsonpath: '$.title',
          displayable:
        )
      ])
  end
end
