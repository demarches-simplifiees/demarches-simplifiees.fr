# frozen_string_literal: true

class APIEntreprise::TvaAdapter < APIEntreprise::Adapter
  # Doc métier : https://entreprise.api.gouv.fr/catalogue/commission_europeenne/numero_tva
  # Swagger : https://entreprise.api.gouv.fr/developpeurs/openapi#tag/Informations-generales/paths/~1v3~1european_commission~1unites_legales~1%7Bsiren%7D~1numero_tva/get

  private

  def get_resource
    api(@procedure_id).tva(siren)
  end

  def process_params
    Sentry.with_scope do |scope|
      data = data_source[:data]
      scope.set_tags(siret: @siret)
      scope.set_extras(source: data)

      result = {}
      if data
        result[:entreprise_numero_tva_intracommunautaire] = data[:tva_number]
      end
      result
    end
  end
end
