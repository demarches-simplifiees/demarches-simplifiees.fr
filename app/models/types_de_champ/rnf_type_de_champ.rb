# frozen_string_literal: true

class TypesDeChamp::RNFTypeDeChamp < TypesDeChamp::TextTypeDeChamp
  include AddressableColumnConcern

  class << self
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
  end

  private

  def paths
    paths = super
    paths.push({
      libelle: "#{libelle} (Nom)",
      description: "#{description} (Nom)",
      path: :nom,
      maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Adresse)",
      description: "#{description} (Adresse)",
      path: :address,
      maybe_null: public? && !mandatory?
    })
    paths.push({
      libelle: "#{libelle} (Code INSEE Ville)",
      description: "#{description} (Code INSEE Ville)",
      path: :code_insee,
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
