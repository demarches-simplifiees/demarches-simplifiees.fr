# frozen_string_literal: true

class APIEntreprise::EtablissementAdapter < APIEntreprise::Adapter
  # Doc Métier : https://entreprise.api.gouv.fr/catalogue/insee/etablissements
  # Swagger : https://entreprise.api.gouv.fr/developpeurs/openapi#tag/Informations-generales/paths/~1v3~1insee~1sirene~1etablissements~1%7Bsiret%7D/get

  private

  def get_resource
    api(@procedure_id).etablissement(@siret)
  end

  def process_params
    raw_data = data_source[:data]
    Sentry.with_scope do |scope|
      scope.set_tags(siret: @siret)
      scope.set_extras(source: raw_data)

      params = raw_data.slice(*attr_to_fetch)
      params[:naf] = raw_data.dig(:activite_principale, :code)
      params[:libelle_naf] = raw_data.dig(:activite_principale, :libelle)

      if valid_params?(params)
        adresse_line = raw_data[:adresse][:acheminement_postal].slice(*address_lines_to_fetch).values.compact.join("\r\n")
        params.merge!(params[:adresse].slice(*address_attr_to_fetch))
        params[:nom_voie] = raw_data[:adresse][:libelle_voie]
        params[:code_insee_localite] = raw_data[:adresse][:code_commune]
        if raw_data[:adresse][:libelle_pays_etranger].present?
          params[:localite] = raw_data[:adresse][:libelle_commune_etranger]
          params[:nom_pays] = raw_data[:adresse][:libelle_pays_etranger]
        else
          params[:localite] = raw_data[:adresse][:libelle_commune]
        end
        params[:adresse] = adresse_line
        params
      else
        {}
      end
    end
  end

  def attr_to_fetch
    [
      :adresse,
      :siret,
      :siege_social,
      :enseigne,
      :diffusable_commercialement
    ]
  end

  def address_attr_to_fetch
    [
      :numero_voie,
      :type_voie,
      :complement_adresse,
      :code_postal
    ]
  end

  def address_lines_to_fetch
    [:l1, :l2, :l3, :l4, :l5, :l6, :l7]
  end
end
