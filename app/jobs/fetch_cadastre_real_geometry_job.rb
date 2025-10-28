# frozen_string_literal: true

class FetchCadastreRealGeometryJob < ApplicationJob
  MAX_ATTEMPT = 10
  discard_on ActiveRecord::RecordNotFound
  discard_on ActiveJob::DeserializationError

  retry_on StandardError, attempts: MAX_ATTEMPT, wait: :polynomially_longer

  def perform(geo_area)
    parcelle_data = APIIgn::API.fetch_parcelle(id: geo_area.parcelle_id)
    if parcelle_data.present?
      geo_area.update_columns(
        cadastre_state: :cadastre_fetched,
        geometry: parcelle_data
      )
    else
      geo_area.update_columns(
        cadastre_state: :cadastre_error,
        cadastre_error: :not_found
      )
    end
  rescue ArgumentError
    if executions == MAX_ATTEMPT
      geo_area.update_columns(
        cadastre_state: :cadastre_error,
        cadastre_error: :api_error
      )
    end
  end
end
