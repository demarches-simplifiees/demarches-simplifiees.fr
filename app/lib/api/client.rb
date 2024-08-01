class API::Client
  include Dry::Monads[:result]

  TIMEOUT = 10

  def call(url:, params: nil, body: nil, json: nil, headers: nil, method: :get, authorization_token: nil, schema: nil, timeout: TIMEOUT)
    response = case method
    when :get
      Typhoeus.get(url,
        headers: headers_with_authorization(headers, false, authorization_token),
        params:,
        timeout: TIMEOUT)
    when :post
      Typhoeus.post(url,
        headers: headers_with_authorization(headers, json, authorization_token),
        body: json.nil? ? body : json.to_json,
        timeout: TIMEOUT)
    end
    handle_response(response, schema:)
  rescue StandardError => reason
    if reason.is_a?(URI::InvalidURIError)
      Failure(Error[:uri, 0, false, reason])
    else
      Failure(Error[:error, 0, false, reason])
    end
  end

  private

  def headers_with_authorization(headers, json, authorization_token)
    headers = headers || {}
    headers['authorization'] = "Bearer #{authorization_token}" if authorization_token.present?
    headers['content-type'] = 'application/json' if json.present?
    headers
  end

  OK = Data.define(:body, :response)
  Error = Data.define(:type, :code, :retryable, :reason)

  def handle_response(response, schema:)
    if response.success?
      scope = Sentry.get_current_scope
      if scope.extra.key?(:external_id)
        scope.set_extras(raw_body: response.body.to_s)
      end
      body = parse_body(response.body)
      case body
      in Success(body)
        if !schema || schema.valid?(body.deep_stringify_keys)
          Success(OK[body, response])
        else
          Failure(Error[:schema, response.code, false, SchemaError.new(schema.validate(body))])
        end
      in Failure(reason)
        Failure(Error[:json, response.code, false, reason])
      end
    elsif response.timed_out?
      Failure(Error[:timeout, response.code, true, HTTPError.new(response)])
    elsif response.code != 0
      Failure(Error[:http, response.code, true, HTTPError.new(response)])
    else
      Failure(Error[:network, response.code, true, HTTPError.new(response)])
    end
  end

  def parse_body(body)
    Success(JSON.parse(body, symbolize_names: true))
  rescue JSON::ParserError => error
    Failure(error)
  end

  class SchemaError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors.to_a

      super(@errors.map(&:to_json).join("\n"))
    end
  end

  class HTTPError < StandardError
    attr_reader :response

    def initialize(response)
      @response = response

      uri = URI.parse(response.effective_url)

      msg = <<~TEXT
        url: #{uri.host}#{uri.path}
        HTTP error code: #{response.code}
        body: #{CGI.escape(response.body)}
        curl message: #{response.return_message}
        total time: #{response.total_time}
        connect time: #{response.connect_time}
        response headers: #{response.headers}
      TEXT

      super(msg)
    end
  end
end
