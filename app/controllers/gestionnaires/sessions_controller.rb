class Gestionnaires::SessionsController < Sessions::SessionsController
  layout "new_application"

  def new
    redirect_to new_user_session_path
  end

  def create
    super
  end

  def after_sign_in_path_for(resource)
    # stored_location_for(resource) ||
    backoffice_path
  end
end
