module NewAdministrateur
  class JetonParticulierController < AdministrateurController
    before_action :retrieve_procedure

    def api_particulier
    end
  end
end
