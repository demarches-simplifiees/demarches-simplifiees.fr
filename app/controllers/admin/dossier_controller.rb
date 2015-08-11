class Admin::DossierController < ApplicationController
  before_action :authenticate_user!

  def show
    @dossier = Dossier.find(params[:dossier_id])
    @entreprise = @dossier.entreprise.decorate
    @etablissement = @dossier.etablissement
    @dossier_pdf = @dossier.dossier_pdf

    @commentaires = @dossier.commentaires.order(created_at: :desc)
    @commentaires = @commentaires.all.decorate
    @commentaire_email = current_user.email

    @dossier = @dossier.decorate
  rescue
    redirect_start
  end

  def index
    @dossier = Dossier.find(params[:dossier_id])
    redirect_to url_for({controller: 'admin/dossier', action: :show, :dossier_id => @dossier.id})
  rescue
    redirect_start
  end

  private

  def redirect_start
    redirect_to url_for({controller: '/start', action: :error_dossier})
  end
end
