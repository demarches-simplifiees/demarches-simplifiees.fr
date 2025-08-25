# frozen_string_literal: true

class DataSources::ReferentielController < ApplicationController
  def search
    if params[:q].present? && params[:q].length > 2 && params[:referentiel_id].present?
      referentiel = Referentiel.find_by(id: params[:referentiel_id])
      return render json: [] if referentiel&.autocomplete_configuration.blank?

      service = ReferentielService.new(referentiel: referentiel)
      result = service.call(params[:q])

      case result
      in Dry::Monads::Success(body)
        formatted = ReferentielAutocompleteRenderService.new(body, referentiel).format_response
        return render json: formatted
      in Dry::Monads::Failure(data)
        Sentry.set_extras(q: params[:q], body: data[:body], code: data[:code]) if data.is_a?(Hash)
        Sentry.capture_message("Referentiel API failure")
      end
    end
    render json: []
  end
end
