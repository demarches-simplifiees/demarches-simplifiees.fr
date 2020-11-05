module Instructeurs
  class ArchivesController < InstructeurController
    before_action :ensure_procedure_enabled

    def index
      @procedure = procedure

      @list_of_months = list_of_months
      @dossiers_termines = @procedure.dossiers.state_termine
      @poids_total = ProcedureArchiveService.poids_total_procedure(@procedure)
      @archives = Archive.for_instructeur(current_instructeur)
    end

    def create
      type = params[:type]
      month = Date.strptime(params[:month], '%Y-%m') if params[:month].present?

      flash[:notice] = "Votre demande a été prise en compte. Selon le nombre de dossiers, cela peut prendre quelques minutes. Vous recevrez un courriel lorsque le fichier sera disponible."
      ArchiveCreationJob.perform_now(procedure, current_instructeur, type, month)
    end

    private

    def ensure_procedure_enabled
      if !Flipper.enabled?(:archive_zip_globale, procedure)
        flash[:alert] = "L'accès aux archives n'est pas disponible pour cette démarche, merci d'en faire la demande à l'équipe de démarches simplifiees"
        return redirect_to url_for(procedure)
      end
    end

    def list_of_months
      months = []
      current_month = procedure.published_at.beginning_of_month
      while current_month < Time.zone.now.end_of_month
        months << current_month
        current_month = current_month.next_month
      end
      months.reverse
    end

    def procedure
      current_instructeur
        .procedures
        .for_download
        .find(params[:procedure_id])
    end
  end
end
