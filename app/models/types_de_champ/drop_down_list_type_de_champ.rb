# frozen_string_literal: true

class TypesDeChamp::DropDownListTypeDeChamp < TypesDeChamp::TypeDeChampBase
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
end
