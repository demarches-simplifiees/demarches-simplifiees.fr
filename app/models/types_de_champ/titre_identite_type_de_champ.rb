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

  def champ_blank?(champ) = champ.piece_justificative_file.blank?

  def columns(procedure:, displayable: nil, prefix: nil)
    [
      Columns::AttachedManyColumn.new(
        procedure_id: procedure.id,
        stable_id:,
        tdc_type: type_champ,
        label: libelle_with_prefix(prefix),
        type: TypeDeChamp.column_type(type_champ),
        displayable: false,
        filterable: false,
        mandatory: mandatory?
      )
    ]
  end
end
