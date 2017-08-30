module NewGestionnaire
  class ProceduresController < GestionnaireController
    before_action :ensure_ownership!, except: [:index]

    def index
      @procedures = current_gestionnaire.procedures.order(archived_at: :desc, published_at: :desc)

      dossiers = current_gestionnaire.dossiers
      @dossiers_count_per_procedure = dossiers.all_state.group(:procedure_id).reorder(nil).count
      @dossiers_a_suivre_count_per_procedure = dossiers.without_followers.en_cours.group(:procedure_id).reorder(nil).count
      @dossiers_archived_count_per_procedure = dossiers.archived.group(:procedure_id).count
      @dossiers_termines_count_per_procedure = dossiers.termine.group(:procedure_id).reorder(nil).count

      @followed_dossiers_count_per_procedure = current_gestionnaire
        .followed_dossiers
        .en_cours
        .where(procedure: @procedures)
        .group(:procedure_id)
        .reorder(nil)
        .count

      @notifications_count_per_procedure = current_gestionnaire.notifications_count_per_procedure
    end

    def show
      @procedure = procedure

      @a_suivre_dossiers = procedure
        .dossiers
        .includes(:user)
        .without_followers
        .en_cours

      @followed_dossiers = current_gestionnaire
        .followed_dossiers
        .includes(:user)
        .where(procedure: @procedure)
        .en_cours

      @followed_dossiers_id = current_gestionnaire
        .followed_dossiers
        .where(procedure: @procedure)
        .pluck(:id)

      @termines_dossiers = procedure.dossiers.includes(:user).termine

      @all_state_dossiers = procedure.dossiers.includes(:user).all_state

      @archived_dossiers = procedure.dossiers.includes(:user).archived

      @statut = params[:statut].present? ? params[:statut] : 'a-suivre'

      @dossiers = case @statut
      when 'a-suivre'
        @a_suivre_dossiers
      when 'suivis'
        @followed_dossiers
      when 'traites'
        @termines_dossiers
      when 'tous'
        @all_state_dossiers
      when 'archives'
        @archived_dossiers
      end
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
