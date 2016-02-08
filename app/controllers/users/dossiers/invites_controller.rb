class Users::Dossiers::InvitesController < UsersController
  def show
    @facade = InviteDossierFacades.new params[:id], current_user.email

    render 'users/recapitulatif/show'
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for users_dossiers_path
  end
end