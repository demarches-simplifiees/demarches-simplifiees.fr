class Users::Dossiers::InvitesController < UsersController
  def authenticate_user!
    session["user_return_to"] = request.fullpath
    return redirect_to new_user_registration_path(user_email: params[:email]) if params[:email].present? && User.find_by(email: params[:email]).nil?

    super
  end

  def show
    @facade = InviteDossierFacades.new params[:id].to_i, current_user.email

    if @facade.dossier.brouillon?
      redirect_to modifier_dossier_path(@facade.dossier)
    else
      render 'users/recapitulatif/show'
    end
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for dossiers_path
  end
end
