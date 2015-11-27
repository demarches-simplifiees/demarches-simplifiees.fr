class Users::SiretController < UsersController
  def index
    @siret = params[:siret] || current_user.siret

    redirect_to(users_path(procedure_id: params['procedure_id'], siret: @siret))
  rescue ActionController::UrlGenerationError
    redirect_to(new_user_session_path)
  end
end
