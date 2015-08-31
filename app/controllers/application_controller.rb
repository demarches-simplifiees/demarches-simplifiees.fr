class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :store_location

  def store_location
    unless params[:controller] == 'devise/sessions'
      url = "/admin/dossiers/#{params[:dossier_id]}"
      session[:user_return_to] = url
    end
  end

  def stored_location_for(resource_or_scope)
    session[:user_return_to] || super
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end
end
