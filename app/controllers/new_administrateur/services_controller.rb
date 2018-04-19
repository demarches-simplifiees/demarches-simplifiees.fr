module NewAdministrateur
  class ServicesController < AdministrateurController
    def index
      @services = services
    end

    private

    def services
      current_administrateur.services
    end
  end
end
