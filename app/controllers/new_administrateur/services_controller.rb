module NewAdministrateur
  class ServicesController < AdministrateurController
    def index
      @services = services.ordered
      @procedure = procedure
    end

    def new
      @procedure = procedure
      @service = Service.new
    end

    def create
      @service = Service.new(service_params)
      @service.administrateur = current_administrateur

      if @service.save
        redirect_to services_path(procedure_id: params[:procedure_id]),
          notice: "#{@service.nom} créé"
      else
        @procedure = procedure
        flash[:alert] = @service.errors.full_messages
        render :new
      end
    end

    def edit
      @service = service
      @procedure = procedure
    end

    def update
      @service = service

      if @service.update(service_params)
        redirect_to services_path(procedure_id: params[:procedure_id]),
          notice: "#{@service.nom} modifié"
      else
        @procedure = procedure
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

    def destroy
      service_to_destroy = service

      if service_to_destroy.procedures.present?
        if service_to_destroy.procedures.count == 1
          message = "la démarche #{service_to_destroy.procedures.first.libelle} utilise encore le service #{service_to_destroy.nom}. Veuillez l'affecter à un autre service avant de pouvoir le supprimer"
        else
          message = "les démarches #{service_to_destroy.procedures.map(&:libelle).join(', ')} utilisent encore le service #{service.nom}. Veuillez les affecter à un autre service avant de pouvoir le supprimer"
        end
        flash[:alert] = message
        redirect_to services_path(procedure_id: params[:procedure_id])
      else
        service_to_destroy.destroy
        redirect_to services_path(procedure_id: params[:procedure_id]),
          notice: "#{service_to_destroy.nom} est supprimé"
      end
    end

    private

    def service_params
      params.require(:service).permit(:nom, :organisme, :siret, :type_organisme, :email, :telephone, :horaires, :adresse)
    end

    def service
      services.find(params[:id])
    end

    def services
      service_ids = current_administrateur.service_ids
      service_ids << maybe_procedure&.service_id
      Service.where(id: service_ids.compact.uniq)
    end

    def procedure_params
      params.require(:procedure).permit(:id, :service_id)
    end

    def maybe_procedure
      current_administrateur.procedures.find_by(id: params[:procedure_id])
    end

    def procedure
      current_administrateur.procedures.find(params[:procedure_id])
    end
  end
end
