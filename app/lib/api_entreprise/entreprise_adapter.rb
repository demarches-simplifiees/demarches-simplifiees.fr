# frozen_string_literal: true

class APIEntreprise::EntrepriseAdapter < APIEntreprise::Adapter
  # Doc métier : https://entreprise.api.gouv.fr/catalogue/insee/unites_legales
  # Swagger : https://entreprise.api.gouv.fr/developpeurs/openapi#tag/Informations-generales/paths/~1v3~1insee~1sirene~1unites_legales~1%7Bsiren%7D/get

  private

  def get_resource
    api(@procedure_id).entreprise(siren)
  end

  def process_params
    params = data_source[:data]
    return {} if params.nil?

    Sentry.with_scope do |scope|
      scope.set_tags(siret: @siret)
      scope.set_extras(source: params)

      params = params.slice(*attr_to_fetch)
      params[:etat_administratif] = map_etat_administratif(data_source)

      if params.present? && valid_params?(params)
        params[:date_creation] = Time.zone.at(params[:date_creation]).to_datetime if params[:date_creation].present?

        forme_juridique = params.extract! :forme_juridique
        if forme_juridique.present?
          params[:forme_juridique] = forme_juridique[:forme_juridique][:libelle]
          params[:forme_juridique_code] = forme_juridique[:forme_juridique][:code]
        end

        personne_morale_attributs = params.extract! :personne_morale_attributs
        if personne_morale_attributs.present?
          params[:raison_sociale] = personne_morale_attributs[:personne_morale_attributs][:raison_sociale]
        end

        personne_physique_attributs = params.extract! :personne_physique_attributs
        if personne_physique_attributs.present?
          params[:nom] = build_nom(personne_physique_attributs)
          params[:prenom] = personne_physique_attributs[:personne_physique_attributs][:prenom_usuel]
        end

        tranche_effectif = params.extract! :tranche_effectif_salarie
        if tranche_effectif.present?
          params[:code_effectif_entreprise] = tranche_effectif[:tranche_effectif_salarie][:code]
        end

        params.transform_keys { |k| :"entreprise_#{k}" }
      else
        {}
      end
    end
  end

  def build_nom(personne_physique_attributs)
    nom_usage = personne_physique_attributs[:personne_physique_attributs][:nom_usage]&.strip
    nom_naissance = personne_physique_attributs[:personne_physique_attributs][:nom_naissance]&.strip

    return nom_usage if nom_naissance.blank? || nom_usage == nom_naissance
    return nom_naissance if nom_usage.blank?
    "#{nom_usage} (#{nom_naissance})"
  end

  def attr_to_fetch
    [
      :siren,
      :forme_juridique,
      :personne_morale_attributs,
      :personne_physique_attributs,
      :raison_sociale,
      :siret_siege_social,
      :tranche_effectif_salarie,
      :date_creation,
    ]
  end

  def map_etat_administratif(data_source)
    raw_value = data_source.dig(:data, :etat_administratif) # data structure will change in v3

    case raw_value
    when 'A' then 'actif'
    when 'F', 'C' then 'fermé'
    end
  end
end
