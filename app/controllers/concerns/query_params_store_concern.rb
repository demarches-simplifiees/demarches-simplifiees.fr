module QueryParamsStoreConcern
  extend ActiveSupport::Concern

  included do
    helper_method :stored_query_params?
  end

  def store_query_params
    # Don't override already stored params, because we could do goings and comings with authentication, and
    # lost previously stored params
    return if stored_query_params? || request.query_parameters.empty?

    session[:stored_params] = request.query_parameters.to_json
  end

  def retrieve_and_delete_stored_query_params
    return {} unless stored_query_params?

    JSON.parse(session.delete(:stored_params))
  end

  def stored_query_params?
    session[:stored_params].present?
  end
end
