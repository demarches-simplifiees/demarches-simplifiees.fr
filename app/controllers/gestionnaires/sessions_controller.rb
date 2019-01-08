class Gestionnaires::SessionsController < Sessions::SessionsController
  def new
    redirect_to new_user_session_path
  end

  def create
    super
  end
end
