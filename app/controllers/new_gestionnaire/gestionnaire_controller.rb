module NewGestionnaire
  class GestionnaireController < ApplicationController
    before_action :authenticate_gestionnaire!
  end
end
