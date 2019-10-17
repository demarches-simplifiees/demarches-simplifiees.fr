module NewAdministrateur
  class GroupeInstructeursController < AdministrateurController
    ITEMS_PER_PAGE = 25

    def index
      @procedure = procedure

      @groupes_instructeurs = procedure
        .groupe_instructeurs
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
        .order(:label)
    end

    private

    def procedure
      current_administrateur
        .procedures
        .includes(:groupe_instructeurs)
        .find(params[:procedure_id])
    end
  end
end
