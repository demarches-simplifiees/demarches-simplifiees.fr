# frozen_string_literal: true

class TypesDeChamp::RNFTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  include AddressableColumnConcern

  def champ_value_for_export(champ, path = :value)
    case path
    when :value
      champ.rnf_id
    when :departement
      champ.departement_code_and_name
    when :code_insee
      champ.commune&.fetch(:code)
    when :address
      champ.full_address
    when :nom
      champ.title
    end
  end

  def champ_value_for_tag(champ, path = :value)
    case path
    when :value
      champ.rnf_id
    when :departement
      champ.departement_code_and_name || ''
    when :code_insee
      champ.commune&.fetch(:code) || ''
    when :address
      champ.full_address || ''
    when :nom
      champ.title || ''
    end
  end

  def champ_blank?(champ) = champ.external_id.blank?

  def columns(procedure:, displayable: true, prefix: nil)
    super
      .concat(addressable_columns(procedure:, displayable:, prefix:))
      .concat([
        Columns::JSONPathColumn.new(
          procedure_id: procedure.id,
          stable_id:,
          tdc_type: type_champ,
          label: "#{libelle_with_prefix(prefix)} – Titre au répertoire national des fondations ",
          type: :text,
          jsonpath: '$.title',
          displayable:,
          mandatory: mandatory?
        ),
      ])
  end

  private

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Nom)",
      description: "#{description} (Nom)",
      path: :nom,
      maybe_null: public? && !mandatory?,
    })
    paths.push({
      libelle: "#{libelle} (Adresse)",
      description: "#{description} (Adresse)",
      path: :address,
      maybe_null: public? && !mandatory?,
    })
    paths.push({
      libelle: "#{libelle} (Code INSEE Ville)",
      description: "#{description} (Code INSEE Ville)",
      path: :code_insee,
      maybe_null: public? && !mandatory?,
    })
    paths.push({
      libelle: "#{libelle} (Département)",
      description: "#{description} (Département)",
      path: :departement,
      maybe_null: public? && !mandatory?,
    })
    paths
  end
end
