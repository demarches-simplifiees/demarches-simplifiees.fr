# frozen_string_literal: true

class DataSources::AdresseController < ApplicationController
  def search
    if params[:q].present? && params[:q].length > 3
      response = fetch_results

      if response.success?
        results = JSON.parse(response.body, symbolize_names: true)

        return render json: APIGeoService.format_address_response(results)
      elsif response.timed_out?
        return head :gateway_timeout
      else
        Sentry.set_extras(body: response.body, code: response.code)
        Sentry.capture_message("Adresse API failure: #{response.return_message}")
        return head :bad_gateway
      end
    end

    render json: []

  rescue JSON::ParserError => e
    Sentry.set_extras(body: response.body, code: response.code)
    Sentry.capture_exception(e)
    return head :server_error
  end

  private

  def fetch_results
    Typhoeus.get("#{API_ADRESSE_URL}/search", params: { q: params[:q], limit: 10 }, timeout: 3)
  end
end
