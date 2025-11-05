# frozen_string_literal: true

class APIEntreprise::RNAAdapter < APIEntreprise::Adapter
  # Doc métier : https://entreprise.api.gouv.fr/catalogue/djepva/associations_open_data
  # Swagger : https://entreprise.api.gouv.fr/developpeurs/openapi#tag/Informations-generales/paths/~1v4~1djepva~1api-association~1associations~1open_data~1%7Bsiren_or_rna%7D/get

  private

  def get_resource
    api(@procedure_id).rna(@siret)
  end

  def process_params
    data, meta = data_source.values_at(:data, :meta)
    return {} if data.nil?

    Sentry.with_scope do |scope|
      scope.set_tags(siret: @siret)
      scope.set_extras(source: data)

      {
        "association_rna" => data[:rna],
        "association_titre" => data[:nom],
        "association_objet" => data[:activites][:objet],
        "association_date_creation" => data[:date_creation],
        # see: https://mattermost.incubateur.net/betagouv/pl/r6txumw9cpyx58rt7iq5dte9qe
        "association_date_declaration" => meta[:date_derniere_mise_a_jour_rna],
        "association_date_publication" => data[:date_publication_journal_officiel],
        "adresse" => data[:adresse_siege],
      }
    end
  end
end
