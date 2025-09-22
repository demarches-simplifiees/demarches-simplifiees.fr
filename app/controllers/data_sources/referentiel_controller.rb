# frozen_string_literal: true

class DataSources::ReferentielController < ApplicationController
  before_action :authenticate_user!
  before_action :mark_as_retryable, :referentiel_service, :referentiel
  MIN_QUERY_LENGTH = 3
  MAX_QUERY_SIZE = 100

  def search
    if query && params[:referentiel_id].present?
      return render json: [] if referentiel&.autocomplete_configuration.blank?

      begin
        result = referentiel_service.call(query)

        case result
        in Dry::Monads::Success
          formatted = ReferentielAutocompleteRenderService.new(result.value!, referentiel).format_response
          return render json: formatted
        in Dry::Monads::Failure(data) if data[:retryable]
          raise RetryableError if @retryable
          Sentry.set_extras(body: data[:body], code: data[:code]) if data.is_a?(Hash)
          Sentry.capture_message("Referentiel API retryable failure")
        in Dry::Monads::Failure(data)
          Sentry.set_extras(body: data[:body], code: data[:code]) if data.is_a?(Hash)
          Sentry.capture_message("Referentiel API failure")
        end
      rescue RetryableError
        @retryable = false
        retry
      rescue StandardError => e
        Sentry.capture_exception(e)
      end
    end
    render json: []
  end

  private

  def mark_as_retryable
    @retryable = true
  end

  def referentiel_service
    @referentiel_service ||= ReferentielService.new(referentiel: referentiel, timeout:)
  end

  def timeout
    ReferentielService::API_TIMEOUT / 2 # due to retry
  end

  def query
    return nil if params[:q].blank?
    return nil if params[:q].length < MIN_QUERY_LENGTH
    return nil if params[:q].length > MAX_QUERY_SIZE

    @query ||= params[:q].strip
  end

  def referentiel
    return @referentiel if defined?(@referentiel)

    @referentiel = Referentiel.find_by(id: params[:referentiel_id])
  end

  class RetryableError < StandardError; end
end
