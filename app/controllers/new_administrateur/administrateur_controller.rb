module NewAdministrateur
  class AdministrateurController < ApplicationController
    layout 'new_application'

    before_action :authenticate_administrateur!
  end
end
