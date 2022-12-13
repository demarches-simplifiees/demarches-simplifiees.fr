module ParamsStoreConcern
  extend ActiveSupport::Concern

  def store_params
    return if session[:stored_params].present?

    session[:stored_params] = params.to_unsafe_h.except(:controller, :action).to_h.to_json
  end

  def stored_params
    return {} if session[:stored_params].blank?

    JSON.parse(session.delete(:stored_params))
  end
end
