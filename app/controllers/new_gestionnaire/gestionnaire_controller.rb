module NewGestionnaire
  class GestionnaireController < ApplicationController
    layout "new_application"

    before_action :authenticate_gestionnaire!
  end
end
