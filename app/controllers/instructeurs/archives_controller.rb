module Instructeurs
  class ArchivesController < InstructeurController
    before_action :ensure_procedure_enabled

    def index
      @procedure = procedure
      @average_dossier_weight = procedure.average_dossier_weight

      @archives_by_period = Archive.by_period(procedure, groupe_instructeurs)

      @archives = Archive
        .for_groupe_instructeur(groupe_instructeurs)
        .to_a
    end

    def create
      period_type = params[:type]
      if period_type == 'monthly'
        period = { month: Date.strptime(params[:month], '%Y-%m') }
      else
        period = { start_day: params[:start_day], end_day: params[:end_day] }
      end

      archive = ProcedureArchiveService.new(procedure).create_pending_archive(current_instructeur, period_type, period)
      if archive.pending?
        ArchiveCreationJob.perform_later(procedure, archive, current_instructeur)
        flash[:notice] = "Votre demande a été prise en compte. Selon le nombre de dossiers, cela peut prendre quelques minutes. Vous recevrez un courriel lorsque le fichier sera disponible."
      else
        flash[:notice] = "Cette archive a déjà été générée."
      end
      redirect_to instructeur_archives_path(procedure)
    end

    private

    def ensure_procedure_enabled
      if !procedure.feature_enabled?(:archive_zip_globale) || procedure.brouillon?
        flash[:alert] = "L'accès aux archives n’est pas disponible pour cette démarche, merci d’en faire la demande à l'équipe de démarches simplifiees"
        return redirect_to instructeur_procedure_path(procedure)
      end
    end

    def procedure_id
      params[:procedure_id]
    end

    def groupe_instructeurs
      current_instructeur
        .groupe_instructeurs
        .where(procedure_id: procedure_id)
    end

    def procedure
      current_instructeur
        .procedures
        .find(procedure_id)
    end
  end
end
