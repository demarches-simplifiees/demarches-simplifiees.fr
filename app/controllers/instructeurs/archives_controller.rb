module Instructeurs
  class ArchivesController < InstructeurController
    before_action :retrieve_procedure
    before_action :ensure_not_super_admin!

    helper_method :create_archive_url

    def index
      @average_dossier_weight = @procedure.average_dossier_weight
      @count_dossiers_termines_by_month = @procedure.dossiers.processed_by_month(groupe_instructeurs).count
      @archives = Archive.for_groupe_instructeur(groupe_instructeurs).to_a
    end

    def create
      type = params[:type]
      archive = Archive.find_or_create_archive(type, year_month, groupe_instructeurs, current_instructeur)
      if archive.pending?
        ArchiveCreationJob.perform_later(@procedure, archive, current_instructeur)
        flash[:notice] = "Votre demande a été prise en compte. Selon le nombre de dossiers, cela peut prendre de quelques minutes à plusieurs heures. Vous recevrez un courriel lorsque le fichier sera disponible."
      else
        flash[:notice] = "Cette archive a déjà été générée."
      end
      redirect_to instructeur_archives_path(@procedure)
    end

    private

    def year_month
      Date.strptime(params[:year_month], '%Y-%m') if params[:year_month].present?
    end

    def create_archive_url(procedure, date)
      instructeur_archives_path(procedure, type: 'monthly', year_month: date.strftime('%Y-%m'))
    end

    def groupe_instructeurs
      current_instructeur
        .groupe_instructeurs
        .where(procedure_id: params[:procedure_id])
    end

    def retrieve_procedure
      @procedure = current_instructeur.procedures.find(params[:procedure_id])
    end
  end
end
