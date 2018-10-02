class Users::Dossiers::InvitesController < UsersController
  def authenticate_user!
    session["user_return_to"] = request.fullpath

    if params[:email].present? && User.find_by(email: params[:email]).nil?
      return redirect_to new_user_registration_path(user: { email: params[:email] })
    end

    super
  end

  def show
    @facade = InviteDossierFacades.new params[:id].to_i, current_user.email

    if @facade.dossier.brouillon?
      redirect_to brouillon_dossier_path(@facade.dossier)
    else
      return redirect_to dossier_path(@facade.dossier)
    end
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for dossiers_path
  end
end
