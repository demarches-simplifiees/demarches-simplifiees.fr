class Users::Dossiers::AddSiretController < ApplicationController
  def show
    @facade = DossierFacades.new params[:dossier_id], current_user.email

    if !@facade.procedure.individual_with_siret?
      raise ActiveRecord::RecordNotFound
    end

    if current_user.siret.present?
      @siret = current_user.siret
    end
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for dossiers_path
  end
end
