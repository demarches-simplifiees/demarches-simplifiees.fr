# frozen_string_literal: true

class TypesDeChamp::EpciTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  def champ_value_for_export(champ, path = :value)
    case path
    when :value
      champ_value(champ)
    when :code
      champ.code
    when :departement
      champ.departement_code_and_name
    end
  end

  def champ_value_for_tag(champ, path = :value)
    case path
    when :value
      champ_value(champ)
    when :code
      champ.code
    when :departement
      champ.departement_code_and_name
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
    paths.push({
      libelle: "#{libelle} (Code)",
      description: "#{description} (Code)",
      path: :code,
      maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Département)",
      description: "#{description} (Département)",
      path: :departement,
      maybe_null: public? && !mandatory?
    })
    paths
  end
end
