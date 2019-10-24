module Instructeurs
  class GroupeInstructeursController < InstructeurController
    ITEMS_PER_PAGE = 25

    def index
      @procedure = procedure
      @groupes_instructeurs = paginated_groupe_instructeurs
    end

    def show
      @procedure = procedure
      @groupe_instructeur = groupe_instructeur
      @instructeurs = paginated_instructeurs
    end

    private

    def procedure
      current_instructeur
        .procedures
        .includes(:groupe_instructeurs)
        .find(params[:procedure_id])
    end

    def groupe_instructeur
      current_instructeur.groupe_instructeurs.find(params[:id])
    end

    def paginated_groupe_instructeurs
      current_instructeur
        .groupe_instructeurs
        .where(procedure: procedure)
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
        .order(:label)
    end

    def paginated_instructeurs
      groupe_instructeur
        .instructeurs
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
        .order(:email)
    end
  end
end
