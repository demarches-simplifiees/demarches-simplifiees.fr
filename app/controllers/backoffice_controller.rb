class BackofficeController < ApplicationController

  def index
    redirect_to(controller: '/gestionnaires/sessions', action: :new) unless gestionnaire_signed_in?
    @dossiers = Dossier.all.decorate
  end
end