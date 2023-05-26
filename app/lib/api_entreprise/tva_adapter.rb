class APIEntreprise::TvaAdapter < APIEntreprise::Adapter
  # Doc métier : https://entreprise.api.gouv.fr/catalogue/commission_europeenne/numero_tva
  # Swagger : https://entreprise.api.gouv.fr/developpeurs/openapi#tag/Informations-generales/paths/~1v3~1european_commission~1unites_legales~1%7Bsiren%7D~1numero_tva/get

  private

  def get_resource
    api(@procedure_id).tva(siren)
  end

  def process_params
    result = {}
    if data_source[:data]
      result[:entreprise_numero_tva_intracommunautaire] = data_source[:data][:tva_number]
    end
    result
  end
end
