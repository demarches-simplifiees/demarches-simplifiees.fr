# frozen_string_literal: true

class TypesDeChamp::CommuneTypeDeChamp < TypesDeChamp::TypeDeChampBase
  class << self
    def champ_value_for_export(champ, path = :value)
      case path
      when :value
        champ_value(champ)
      when :departement
        champ.departement_code_and_name || ''
      when :code
        champ.code || ''
      end
    end

    def champ_value_for_tag(champ, path = :value)
      case path
      when :value
        champ_value(champ)
      when :departement
        champ.departement_code_and_name || ''
      when :code
        champ.code || ''
      end
    end

    def champ_value(champ)
      champ.code_postal? ? "#{champ.name} (#{champ.code_postal})" : champ.name
    end
  end

  private

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Code INSEE)",
      description: "#{description} (Code INSEE)",
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
