class API::V2::GraphqlController < API::V2::BaseController
  def execute
    variables = ensure_hash(params[:variables])

    result = Api::V2::Schema.execute(params[:query],
      variables: variables,
      context: context,
      operation_name: params[:operationName])

    render json: result
  rescue => e
    if Rails.env.development?
      handle_error_in_development e
    else
      raise e
    end
  end

  private

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { error: { message: e.message, backtrace: e.backtrace }, data: {} }, status: 500
  end
end
