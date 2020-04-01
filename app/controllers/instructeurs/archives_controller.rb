module Instructeurs
  class ArchivesController < InstructeurController
    def index
      @procedure = procedure
      if !@procedure.publiee?
        flash[:alert] = "L'accès aux archives n'est disponible que pour les démarches publiées"
        return redirect_to url_for(@procedure)
      end

      @list_of_months = list_of_months
      @dossiers_termines = @procedure.dossiers.state_termine
      @poids_total = ProcedureArchiveService.poids_total_procedure(@procedure)
      @archives = current_instructeur.archives.where(procedure: procedure)
    end

    def create
      type = params[:type]
      month = Date.strptime(params[:month], '%Y-%m') if params[:month].present?

      flash[:notice] = "Votre demande a été prise en compte. Selon le nombre de dossiers, cela peut prendre quelques minutes. Vous recevrez un courriel lorsque le fichier sera disponible."
      ArchiveCreationJob.perform_later(procedure, current_instructeur, type, month)
    end

    private

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
