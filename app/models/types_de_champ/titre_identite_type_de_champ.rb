# frozen_string_literal: true

class TypesDeChamp::TitreIdentiteTypeDeChamp < TypesDeChamp::TypeDeChampBase
  FRANCE_CONNECT = 'france_connect'
  PIECE_JUSTIFICATIVE = 'piece_justificative'

  def estimated_fill_duration(revision)
    FILL_DURATION_LONG
  end

  def tags_for_template = [].freeze

  def champ_value_for_export(champ, path = :value)
    champ.piece_justificative_file.attached? ? "présent" : "absent"
  end

  def champ_value_for_api(champ, version: 2)
    nil
  end

  def champ_default_export_value(path = :value)
    "absent"
  end

  def columns(procedure_id:, displayable: nil, prefix: nil)
    [
      Columns::TitreIdentiteColumn.new(
        procedure_id:,
        table: Column::TYPE_DE_CHAMP_TABLE,
        column: stable_id.to_s,
        label: libelle_with_prefix(prefix),
        type: TypeDeChamp.column_type(type_champ),
        value_column: TypeDeChamp.value_column(type_champ),
        displayable: false,
        filterable: false
      )
    ]
  end
end
