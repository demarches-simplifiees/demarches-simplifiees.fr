class Users::Dossiers::AddSiretController < ApplicationController
  def show
    @facade =  DossierFacades.new params[:dossier_id], current_user.email

    raise ActiveRecord::RecordNotFound unless @facade.procedure.individual_with_siret?

    @siret = current_user.siret unless current_user.siret.nil?

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for users_dossiers_path
  end
end
