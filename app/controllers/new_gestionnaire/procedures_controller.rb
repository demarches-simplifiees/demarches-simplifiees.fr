module NewGestionnaire
  class ProceduresController < GestionnaireController
    layout "new_application"

    before_action :ensure_ownership!, except: [:index]

    def index
      @procedures = current_gestionnaire.procedures

      dossiers = current_gestionnaire.dossiers.state_not_brouillon
      @dossiers_count_per_procedure = dossiers.group(:procedure_id).count
      @dossiers_nouveaux_count_per_procedure = dossiers.state_nouveaux.group(:procedure_id).count
      @dossiers_archived_count_per_procedure = dossiers.archived.group(:procedure_id).count

      @followed_dossiers_count_per_procedure = current_gestionnaire.followed_dossiers.where(procedure: @procedures).group(:procedure_id).count
    end

    def show
      @procedure = procedure

      @a_suivre_dossiers = procedure
        .dossiers
        .without_followers
        .en_cours

      @followed_dossiers = current_gestionnaire
        .followed_dossiers
        .where(procedure: @procedure)
        .en_cours

      @termines_dossiers = procedure.dossiers.termine

      @all_state_dossiers = procedure.dossiers.all_state

      @archived_dossiers = procedure.dossiers.archived
    end

    private

    def procedure
      Procedure.find(params[:procedure_id])
    end

    def ensure_ownership!
      if !procedure.gestionnaires.include?(current_gestionnaire)
        flash[:alert] = "Vous n'avez pas accès à cette procédure"
        redirect_to root_path
      end
    end
  end
end
