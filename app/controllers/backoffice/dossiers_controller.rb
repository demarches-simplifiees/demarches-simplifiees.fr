class Backoffice::DossiersController < ApplicationController
  before_action :authenticate_gestionnaire!

  def show
    initialize_instance_params params[:id]
  end

  def a_traiter
    @dossiers_a_traiter = Dossier.a_traiter(current_gestionnaire)
    @dossiers_a_traiter = @dossiers_a_traiter.paginate(:page => params[:page], :per_page => 12).decorate

    total_dossiers_per_state
  end

  def en_attente
    @dossiers_en_attente = Dossier.en_attente(current_gestionnaire)
    @dossiers_en_attente = @dossiers_en_attente.paginate(:page => params[:page], :per_page => 12).decorate
    total_dossiers_per_state
  end

  def termine
    @dossiers_termine = Dossier.termine(current_gestionnaire)
    @dossiers_termine = @dossiers_termine.paginate(:page => params[:page], :per_page => 12).decorate
    total_dossiers_per_state
  end

  def search
    @search_terms = params[:q]

    @dossiers_search, @dossier = Dossier.search(current_gestionnaire, @search_terms)

    unless @dossiers_search.empty?
      @dossiers_search = @dossiers_search.paginate(:page => params[:page], :per_page => 12).decorate
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
    @dossiers_a_traiter_total = !@dossiers_a_traiter.nil? ? @dossiers_a_traiter.size : Dossier.a_traiter(current_gestionnaire).size
    @dossiers_en_attente_total = !@dossiers_en_attente.nil? ? @dossiers_en_attente.size : Dossier.en_attente(current_gestionnaire).size
    @dossiers_termine_total = !@dossiers_termine.nil? ? @dossiers_termine.size : Dossier.termine(current_gestionnaire).size
  end

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
