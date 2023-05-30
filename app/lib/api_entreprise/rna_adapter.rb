class APIEntreprise::RNAAdapter < APIEntreprise::Adapter
  # Doc métier : https://entreprise.api.gouv.fr/catalogue/djepva/associations_open_data
  # Swagger : https://entreprise.api.gouv.fr/developpeurs/openapi#tag/Informations-generales/paths/~1v4~1djepva~1api-association~1associations~1open_data~1%7Bsiren_or_rna%7D/get

  private

  def get_resource
    api(@procedure_id).rna(@siret)
  end

  def process_params
    data = data_source[:data]
    return {} if data.nil?

    Sentry.with_scope do |scope|
      scope.set_tags(siret: @siret)
      scope.set_extras(source: data)

      {
        "association_rna" => data[:rna],
        "association_titre" => data[:nom],
        "association_objet" => data[:activites][:objet],
        "association_date_creation" => data[:date_creation],
        "association_date_declaration" => data[:date_publication_journal_officiel],
        "association_date_publication" => data[:date_publication_journal_officiel]
      }
    end
  end
end
