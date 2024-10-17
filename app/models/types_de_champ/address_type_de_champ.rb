# frozen_string_literal: true

class TypesDeChamp::AddressTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def libelles_for_export
    path = paths.first
    [[path[:libelle], path[:path]]]
  end

  def champ_value(champ)
    champ.address_label.presence || ''
  end

  def champ_value_for_api(champ, version = 2)
    champ_value(champ)
  end

  def champ_value_for_tag(champ, path = :value)
    case path
    when :value
      champ_value(champ)
    when :departement
      champ.departement_code_and_name || ''
    when :commune
      champ.commune_name || ''
    end
  end

  def champ_value_for_export(champ, path = :value)
    case path
    when :value
      champ_value(champ)
    when :departement
      champ.departement_code_and_name
    when :commune
      champ.commune_name
    end
  end

  def champ_value_for_logic(champ)
    {
      code_departement: champ.code_departement,
      code_region: champ.code_region
    }
  end

  private

  def paths
    paths = super
    paths.push(
      {
        libelle: "#{libelle} (Département)",
        path: :departement,
        description: "#{description} (Département)"
      },
      {
        libelle: "#{libelle} (Commune)",
        path: :commune,
        description: "#{description} (Commune)"
      }
    )
    paths
  end
end
