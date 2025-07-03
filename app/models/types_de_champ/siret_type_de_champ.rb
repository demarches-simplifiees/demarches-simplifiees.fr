# frozen_string_literal: true

class TypesDeChamp::SiretTypeDeChamp < TypesDeChamp::TypeDeChampBase
  include AddressableColumnConcern

  def estimated_fill_duration(revision)
    FILL_DURATION_MEDIUM
  end

  def champ_blank_or_invalid?(champ) = Siret.new(siret: champ.value).invalid?

  def columns(procedure:, displayable: true, prefix: nil)
    super
      .concat(etablissement_columns(procedure:, displayable:, prefix:))
      .concat(addressable_columns(procedure:, displayable:, prefix:))
  end

  private

  def etablissement_columns(procedure:, displayable:, prefix:)
    i18n_scope = [:activerecord, :attributes, :procedure_presentation, :fields, :etablissement]

    Etablissement::DISPLAYABLE_COLUMNS.map do |(column, attributes)|
      Columns::JSONPathColumn.new(
        procedure_id: procedure.id,
        stable_id:,
        tdc_type: type_champ,
        label: [prefix, libelle, I18n.t(column, scope: i18n_scope)].compact.join(' – '),
        type: attributes[:type],
        jsonpath: "$.#{column}",
        displayable: true,
        filterable: attributes.fetch(:filterable, true),
        mandatory: mandatory?
      )
    end
  end
end
