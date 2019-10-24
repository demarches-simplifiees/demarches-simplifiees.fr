module Instructeurs
  class GroupeInstructeursController < InstructeurController
    ITEMS_PER_PAGE = 25

    def index
      @procedure = procedure
      @groupes_instructeurs = paginated_groupe_instructeurs
    end

    private

    def procedure
      current_instructeur
        .procedures
        .includes(:groupe_instructeurs)
        .find(params[:procedure_id])
    end

    def paginated_groupe_instructeurs
      current_instructeur
        .groupe_instructeurs
        .where(procedure: procedure)
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
        .order(:label)
    end
  end
end
