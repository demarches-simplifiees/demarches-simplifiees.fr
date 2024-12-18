# frozen_string_literal: true

class TypesDeChamp::DropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def columns(procedure:, displayable: true, prefix: nil)
    if referentiel_mode?
      referentiel.headers.map do |header|
        Columns::JSONPathColumn.new(
          procedure_id: procedure.id,
          stable_id:,
          tdc_type: type_champ,
          label: "#{libelle_with_prefix(prefix)} – Référentiel #{header}",
          type: :enum,
          jsonpath: "$.referentiel.data.row.#{header.parameterize.underscore}",
          displayable:,
          options_for_select: referentiel.items.map { _1.data['row'][header.parameterize.underscore] }.uniq.sort
        )
      end
    else
      super
    end
  end
end
