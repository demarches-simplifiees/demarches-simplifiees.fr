module NewAdministrateur
  class ServicesController < AdministrateurController
    def index
      @services = services.ordered
      @procedure = procedure
    end

    def new
    end

    def create
      new_service = Service.new(service_params)
      new_service.administrateur = current_administrateur

      if new_service.save
        redirect_to services_path(procedure_id: params[:procedure_id]),
          notice: "#{new_service.nom} créé"
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
        redirect_to services_path(procedure_id: params[:procedure_id]),
          notice: "#{@service.nom} modifié"
      else
        flash[:alert] = @service.errors.full_messages
        render :edit
      end
    end

    def add_to_procedure
      procedure = current_administrateur.procedures.find(procedure_params[:id])
      service = services.find(procedure_params[:service_id])

      procedure.update(service: service)

      redirect_to admin_procedure_path(procedure.id),
        notice: "service affecté : #{procedure.service.nom}"
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

    def procedure_params
      params.require(:procedure).permit(:id, :service_id)
    end

    def procedure
      current_administrateur.procedures.find(params[:procedure_id])
    end
  end
end
