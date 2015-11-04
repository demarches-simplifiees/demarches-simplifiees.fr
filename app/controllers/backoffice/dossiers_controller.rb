class Backoffice::DossiersController < ApplicationController
  before_action :authenticate_gestionnaire!

  def show
    initialize_instance_params params[:id]
  end

  def valid
    initialize_instance_params params[:dossier_id]

    @dossier.next_step! 'gestionnaire', 'valid'
    flash.notice = 'Dossier confirmé avec succès.'

    render 'show'
  end

  def close
    initialize_instance_params params[:dossier_id]

    @dossier.next_step! 'gestionnaire', 'close'
    flash.notice = 'Dossier traité avec succès.'

    render 'show'
  end

  private

  def initialize_instance_params dossier_id
    @dossier = Dossier.find(dossier_id)
    @entreprise = @dossier.entreprise.decorate
    @etablissement = @dossier.etablissement
    @pieces_justificatives = @dossier.pieces_justificatives
    @commentaires = @dossier.ordered_commentaires
    @commentaires = @commentaires.all.decorate
    @commentaire_email = current_gestionnaire.email

    @procedure = @dossier.procedure

    @dossier = @dossier.decorate
    @champs = @dossier.ordered_champs
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(controller: '/backoffice')
  end
end
