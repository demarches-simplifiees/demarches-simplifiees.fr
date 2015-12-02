class Backoffice::DossiersController < ApplicationController
  before_action :authenticate_gestionnaire!

  def show
    initialize_instance_params params[:id]
  end

  def a_traiter
    @dossiers = current_gestionnaire.dossiers.waiting_for_gestionnaire
                    .paginate(:page => params[:page]).decorate

    @page = 'a_traiter'
    total_dossiers_per_state
  end

  def en_attente
    @dossiers = current_gestionnaire.dossiers.waiting_for_user()
                    .paginate(:page => params[:page]).decorate

    @page = 'en_attente'
    total_dossiers_per_state
  end

  def termine
    @dossiers = current_gestionnaire.dossiers.termine()
                    .paginate(:page => params[:page]).decorate

    @page = 'termine'
    total_dossiers_per_state
  end

  def search
    @search_terms = params[:q]

    @dossiers_search, @dossier = Dossier.search(current_gestionnaire, @search_terms)

    unless @dossiers_search.empty?
      @dossiers_search = @dossiers_search.paginate(:page => params[:page]).decorate
    end

    @dossier = @dossier.decorate unless @dossier.nil?

    total_dossiers_per_state
  rescue RuntimeError
    @dossiers_search = []
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

  def total_dossiers_per_state
    @dossiers_a_traiter_total = !@dossiers_a_traiter.nil? ? @dossiers_a_traiter.size : current_gestionnaire.dossiers.waiting_for_gestionnaire.size
    @dossiers_en_attente_total = !@dossiers_en_attente.nil? ? @dossiers_en_attente.size : current_gestionnaire.dossiers.waiting_for_user.size
    @dossiers_termine_total = !@dossiers_termine.nil? ? @dossiers_termine.size : current_gestionnaire.dossiers.termine.size
  end

  def initialize_instance_params dossier_id
    @dossier = Dossier.where(archived: false).find(dossier_id)
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
