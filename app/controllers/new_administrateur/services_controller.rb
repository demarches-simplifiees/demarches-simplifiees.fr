module NewAdministrateur
  class ServicesController < AdministrateurController
    def index
      @services = services.ordered
    end

    def new
    end

    def create
      new_service = Service.new(service_params)
      new_service.administrateur = current_administrateur

      if new_service.save
        redirect_to services_path, notice: "#{new_service.nom} créé"
      else
        flash[:alert] = new_service.errors.full_messages
        render :new
      end
    end

    def edit
      @service = service
    end

    def update
      @service = service

      if @service.update(service_params)
        redirect_to services_path, notice: "#{@service.nom} modifié"
      else
        flash[:alert] = @service.errors.full_messages
        render :edit
      end
    end

    private

    def service_params
      params.require(:service).permit(:nom, :type_organisme)
    end

    def service
      services.find(params[:id])
    end

    def services
      current_administrateur.services
    end
  end
end
