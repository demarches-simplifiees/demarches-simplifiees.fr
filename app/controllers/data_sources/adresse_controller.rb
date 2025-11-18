# frozen_string_literal: true

class DataSources::AdresseController < ApplicationController
  def search
    query = clean_query(params[:q])

    if query.present?
      response = fetch_results(query)

      if response.success?
        results = JSON.parse(response.body, symbolize_names: true)

        return render json: APIGeoService.format_address_response(results)
      elsif response.timed_out?
        return head :gateway_timeout
      else
        if response.code == 0
          error_message = response.return_message
        else
          Sentry.set_extras(body: response.body, code: response.code)
          error_message = JSON.parse(response.body, symbolize_names: true).dig(:message)
        end

        Sentry.capture_message("Adresse API failure: #{error_message}")
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

  def clean_query(query)
    # this method prevents API errors :
    # {"code":400,"message":"Failed parsing query","detail":["q: must contain between 3 and 200 chars and start with a number or a letter"]}

    sanitized = query.to_s.strip
    sanitized = sanitized.gsub(/\s+/, " ") # replace multiple spaces with a single space
    sanitized = sanitized.sub(/\A[^[:alnum:]]+/, "") # remove leading non-alphanumeric characters

    return nil if sanitized.length < 3
    sanitized = sanitized[0...200] if sanitized.length > 200

    sanitized
  end

  def fetch_results(query)
    Typhoeus.get("#{API_ADRESSE_URL}/search", params: { q: query, limit: 10 }, timeout: 3)
  end
end
