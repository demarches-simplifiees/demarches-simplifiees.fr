class BackofficeController < ApplicationController

  def index
    if !gestionnaire_signed_in?
      redirect_to(controller: '/gestionnaires/sessions', action: :new)
    else
      redirect_to(:backoffice_dossiers)
    end
  end
end