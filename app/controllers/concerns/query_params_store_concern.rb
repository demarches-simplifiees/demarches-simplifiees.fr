module QueryParamsStoreConcern
  extend ActiveSupport::Concern

  def store_query_params
    # Don't override already stored params, because we could do goings and comings with authentication, and
    # lost previously stored params
    return if session[:stored_params].present? || request.query_parameters.empty?

    session[:stored_params] = request.query_parameters.to_json
  end

  def retrieve_and_delete_stored_query_params
    return {} if session[:stored_params].blank?

    JSON.parse(session.delete(:stored_params))
  end
end
