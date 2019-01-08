module NewAdministrateur
  class AdministrateurController < ApplicationController
    before_action :authenticate_administrateur!
  end
end
