class API::V2::GraphqlController < API::V2::BaseController
  def execute
    result = API::V2::Schema.execute(query:, variables:, context:, operation_name:)
    @query_info = result.context.query_info

    render json: result
  rescue GraphQL::ParseError, JSON::ParserError => exception
    handle_parse_error(exception, :graphql_parse_failed)
  rescue ArgumentError => exception
    handle_parse_error(exception, :bad_request)
  rescue => exception
    if Rails.env.production?
      handle_error_in_production(exception)
    else
      handle_error_in_development(exception)
    end
  end

  private

  def request_logs(logs)
    super

    logs.merge!(@query_info.presence || {})
  end

  def process_action(*args)
    super
  rescue ActionDispatch::Http::Parameters::ParseError => exception
    render json: {
      errors: [
        {
          message: exception.cause.message,
          extensions: {
            code: :bad_request
          }
        }
      ],
      data: nil
    }, status: 400
  end

  def query
    if params[:queryId].present?
      API::V2::StoredQuery.get(params[:queryId])
    else
      params[:query]
    end
  end

  def variables
    ensure_hash(params[:variables])
  end

  def operation_name
    params[:operationName]
  end

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash
      ambiguous_param
    when ActionController::Parameters
      ambiguous_param.to_unsafe_h
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def handle_parse_error(exception, code)
    render json: {
      errors: [
        {
          message: exception.message,
          extensions: { code: }
        }
      ],
      data: nil
    }, status: 400
  end

  def handle_error_in_development(exception)
    logger.error exception.message
    logger.error exception.backtrace.join("\n")

    render json: {
      errors: [
        {
          message: exception.message,
          extensions: {
            code: :internal_server_error,
            backtrace: exception.backtrace
          }
        }
      ],
      data: nil
    }, status: 500
  end

  def handle_error_in_production(exception)
    exception_id = SecureRandom.uuid
    Sentry.with_scope do |scope|
      scope.set_tags(exception_id:)
      Sentry.capture_exception(exception)
    end

    render json: {
      errors: [
        {
          message: "Internal Server Error",
          extensions: {
            code: :internal_server_error,
            exception_id:
          }
        }
      ],
      data: nil
    }, status: 500
  end
end
