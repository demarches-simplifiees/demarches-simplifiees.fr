# frozen_string_literal: true

class TypesDeChamp::DropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def champ_value_for_export(champ, path = :value)
    if referentiel_mode? && path != :value
      champ.referentiel_item_value(path)
    else
      super
    end
  end

  def champ_value_for_tag(champ, path = :value)
    if referentiel_mode?
      champ.referentiel_item_value(path)
    else
      super
    end
  end

  def columns(procedure:, displayable: true, prefix: nil)
    if referentiel_mode?
      referentiel.headers_with_path.map do |(header, path)|
        Columns::JSONPathColumn.new(
          procedure_id: procedure.id,
          stable_id:,
          tdc_type: type_champ,
          label: "#{libelle_with_prefix(prefix)} – Référentiel #{header}",
          type: :enum,
          jsonpath: "$.referentiel.data.row.#{path}",
          displayable:,
          options_for_select: referentiel.options_for_path(path)
        )
      end
    else
      super
    end
  end

  def paths
    if referentiel_mode? && referentiel.present?
      referentiel.headers_with_path.map do |(header, path)|
        {
          libelle: "#{libelle} (#{header})",
          description: "#{description} (#{header})",
          path:,
          maybe_null: public? && !mandatory?
        }
      end
    else
      super
    end
  end
end
