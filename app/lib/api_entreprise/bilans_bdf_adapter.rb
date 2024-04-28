# frozen_string_literal: true

class APIEntreprise::BilansBdfAdapter < APIEntreprise::Adapter
  def initialize(siret, procedure_id)
    @siret = siret
    @procedure_id = procedure_id
  end

  private

  def get_resource
    api(@procedure_id).bilans_bdf(siren)
  end

  def process_params
    Sentry.with_scope do |scope|
      data = data_source[:data]
      scope.set_tags(siret: @siret)
      scope.set_extras(source: data)

      result = {}
      if data
        result[:entreprise_bilans_bdf] = data
        result[:entreprise_bilans_bdf_monnaie] = 'euros'
      end
      result
    end
  end
end
