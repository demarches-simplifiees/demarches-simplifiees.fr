module Instructeurs
  class ArchivesController < InstructeurController
    before_action :ensure_procedure_enabled

    def index
      @procedure = procedure

      @archivable_months = archivable_months
      @dossiers_termines = @procedure.dossiers.state_termine
      @poids_total = ProcedureArchiveService.procedure_files_size(@procedure)
      groupe_instructeur = current_instructeur.groupe_instructeurs.where(procedure: @procedure.id).first
      @archives = Archive.for_groupe_instructeur(groupe_instructeur)
    end

    def create
      type = params[:type]
      month = Date.strptime(params[:month], '%Y-%m') if params[:month].present?

      ArchiveCreationJob.perform_later(procedure, current_instructeur, type, month)
      flash[:notice] = "Votre demande a été prise en compte. Selon le nombre de dossiers, cela peut prendre quelques minutes. Vous recevrez un courriel lorsque le fichier sera disponible."
    end

    private

    def ensure_procedure_enabled
      if !procedure.publiee?
        flash[:alert] = "L'accès aux archives n'est pas disponible pour cette démarche, merci d'en faire la demande à l'équipe de démarches simplifiees"
        return redirect_to instructeur_procedure_path(procedure)
      end
    end

    def archivable_months
      start_date = procedure.published_at.to_date
      end_date = Time.zone.now.to_date

      (start_date...end_date)
        .map(&:beginning_of_month)
        .uniq
        .reverse
    end

    def procedure
      current_instructeur
        .procedures
        .for_download
        .find(params[:procedure_id])
    end
  end
end
