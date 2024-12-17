# frozen_string_literal: true

class TypesDeChamp::DropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def champ_value_for_export(champ, path = :value)
    if referentiel? && path != :value
      champ.referentiel_item_data&.dig(path)
    else
      champ.value
    end
  end

  def columns(procedure:, displayable: true, prefix: nil)
    if referentiel?
      referentiel.headers.map do |header|
        Columns::JSONPathColumn.new(
          procedure_id: procedure.id,
          stable_id:,
          tdc_type: type_champ,
          label: "#{libelle_with_prefix(prefix)} – Référentiel #{header}",
          type: :text,
          jsonpath: "$.referentiel.data.#{header.parameterize.underscore}",
          displayable:
        )
      end
    else
      super
    end
  end

  def paths
    paths = []
    if referentiel? && referentiel.present?
      referentiel.headers.each do |header|
        paths.push({
          libelle: "#{libelle} (#{header})",
          description: "#{description} (#{header})",
          path: header.parameterize.underscore,
          maybe_null: public? && !mandatory?
        })
      end
      paths
    else
      super
    end
  end
end
