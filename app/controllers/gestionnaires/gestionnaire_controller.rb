module Gestionnaires
  class GestionnaireController < ApplicationController
    before_action :authenticate_gestionnaire!

    def nav_bar_profile
      :gestionnaire
    end
  end
end
