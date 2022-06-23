module Administrateurs
  class ArchivesController < AdministrateurController
    before_action :retrieve_procedure, only: [:index, :create]
    helper_method :create_archive_url
    def index
      @exports = Export.find_for_groupe_instructeurs(@procedure.groupe_instructeur_ids, nil)
      @average_dossier_weight = @procedure.average_dossier_weight
      @count_dossiers_termines_by_month = Traitement.count_dossiers_termines_by_month(@procedure.groupe_instructeurs)
      @archives = Archive.for_groupe_instructeur(@procedure.groupe_instructeurs).to_a
    end

    def create
      type = params[:type]
      month = Date.strptime(params[:month], '%Y-%m') if params[:month].present?

      archive = ProcedureArchiveService.new(@procedure).create_pending_archive(@procedure.groupe_instructeurs, type, month)
      if archive.pending?
        ArchiveCreationJob.perform_later(@procedure, archive, current_administrateur)
        flash[:notice] = "Votre demande a été prise en compte. Selon le nombre de dossiers, cela peut prendre de quelques minutes a plusieurs heures. Vous recevrez un courriel lorsque le fichier sera disponible."
      else
        flash[:notice] = "Cette archive a déjà été générée."
      end
      redirect_to admin_procedure_archives_path(@procedure)
    end

    def create_archive_url(procedure, month)
      admin_procedure_archives_path(procedure, type: 'monthly', month: month.strftime('%Y-%m'))
    end

  end
end
