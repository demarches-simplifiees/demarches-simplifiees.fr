class BackofficeController < ApplicationController

  def index
    if !gestionnaire_signed_in?
      redirect_to(controller: '/gestionnaires/sessions', action: :new)
    else
      @dossiers_a_traiter = Dossier.a_traiter(current_gestionnaire).decorate
      @dossiers_en_attente = Dossier.en_attente(current_gestionnaire).decorate
      @dossiers_termine = Dossier.termine(current_gestionnaire).decorate
    end
  end
end