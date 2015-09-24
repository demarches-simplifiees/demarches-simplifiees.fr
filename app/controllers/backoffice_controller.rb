class BackofficeController < ApplicationController

  def index
    redirect_to(controller: '/gestionnaires/sessions', action: :new) unless gestionnaire_signed_in?
    @dossiers_a_traiter = Dossier.a_traiter.decorate
    @dossiers_en_attente = Dossier.en_attente.decorate
    @dossiers_termine = Dossier.termine.decorate
  end
end