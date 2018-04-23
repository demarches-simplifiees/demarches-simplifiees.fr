module NewAdministrateur
  class ServicesController < AdministrateurController
    def index
      @services = services.ordered
    end

    private

    def services
      current_administrateur.services
    end
  end
end
