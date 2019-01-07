class Administrateurs::SessionsController < Sessions::SessionsController
  def new
    redirect_to new_user_session_path
  end

  def create
    super
  end

  def after_sign_in_path_for(resource)
    admin_procedures_path
  end
end
