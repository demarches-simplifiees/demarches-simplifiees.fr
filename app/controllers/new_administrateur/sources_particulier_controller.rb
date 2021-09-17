module NewAdministrateur
  class SourcesParticulierController < AdministrateurController
    before_action :retrieve_procedure

    def show
      sources_service = APIParticulier::Services::SourcesService.new(@procedure)
      @available_sources = sources_service.available_sources
    end

    def update
    end
  end
end
