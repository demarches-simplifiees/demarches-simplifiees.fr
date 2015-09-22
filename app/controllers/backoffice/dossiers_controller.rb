class Backoffice::DossiersController < ApplicationController
  before_action :authenticate_gestionnaire!

  def show
    @dossier = Dossier.find(params[:id])
    @entreprise = @dossier.entreprise.decorate
    @etablissement = @dossier.etablissement
    @pieces_justificatives = @dossier.pieces_justificatives
    @commentaires = @dossier.commentaires.order(created_at: :desc)
    @commentaires = @commentaires.all.decorate
    @commentaire_email = current_gestionnaire.email

    @procedure = @dossier.procedure

    @dossier = @dossier.decorate
  rescue ActiveRecord::RecordNotFound
    redirect_start
  end

  private

  def redirect_start
    redirect_to url_for(controller: '/start', action: :error_dossier)
  end
end
