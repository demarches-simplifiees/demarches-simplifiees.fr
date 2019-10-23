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

    def show
      @procedure = procedure
      @groupe_instructeur = groupe_instructeur
      @instructeurs = groupe_instructeur
        .instructeurs
        .page(params[:page])
        .per(ITEMS_PER_PAGE)
        .order(:email)
    end

    private

    def procedure
      current_administrateur
        .procedures
        .includes(:groupe_instructeurs)
        .find(params[:procedure_id])
    end

    def groupe_instructeur
      procedure.groupe_instructeurs.find(params[:id])
    end
  end
end
