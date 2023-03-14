module Administrateurs
  class ArchivesController < AdministrateurController
    before_action :retrieve_procedure
    before_action :ensure_not_super_admin!

    helper_method :create_archive_url

    def index
      @exports = Export.find_for_groupe_instructeurs(all_groupe_instructeurs.map(&:id), nil)
      @average_dossier_weight = @procedure.average_dossier_weight
      @count_dossiers_termines_by_month = @procedure.dossiers.processed_by_month(all_groupe_instructeurs).count
      @archives = Archive.for_groupe_instructeur(all_groupe_instructeurs).to_a
    end

    def create
      type = params[:type]
      archive = Archive.find_or_create_archive(type, year_month, all_groupe_instructeurs)
      if archive.pending?
        ArchiveCreationJob.perform_later(@procedure, archive, current_administrateur)
        flash[:notice] = "Votre demande a été prise en compte. Selon le nombre de dossiers, cela peut prendre de quelques minutes a plusieurs heures. Vous recevrez un courriel lorsque le fichier sera disponible."
      else
        flash[:notice] = "Cette archive a déjà été générée."
      end
      redirect_to admin_procedure_archives_path(@procedure)
    end

    private

    def year_month
      Date.strptime(params[:year_month], '%Y-%m') if params[:year_month].present?
    end

    def all_groupe_instructeurs
      @procedure.groupe_instructeurs
    end

    def create_archive_url(procedure, date)
      admin_procedure_archives_path(procedure, type: 'monthly', year_month: date.strftime('%Y-%m'))
    end
  end
end
