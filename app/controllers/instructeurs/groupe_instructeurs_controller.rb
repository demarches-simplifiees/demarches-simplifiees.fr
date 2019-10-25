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

    def add_instructeur
      @instructeur = Instructeur.find_by(email: instructeur_email) ||
        create_instructeur(instructeur_email)

      if groupe_instructeur.instructeurs.include?(@instructeur)
        flash[:alert] = "L’instructeur « #{instructeur_email} » est déjà dans le groupe."

      else
        groupe_instructeur.instructeurs << @instructeur
        flash[:notice] = "L’instructeur « #{instructeur_email} » a été affecté au groupe."
        GroupeInstructeurMailer
          .add_instructeur(groupe_instructeur, @instructeur, current_user.email)
          .deliver_later
      end

      redirect_to instructeur_groupe_path(procedure, groupe_instructeur)
    end

    private

    def create_instructeur(email)
      user = User.create_or_promote_to_instructeur(
        email,
        SecureRandom.hex,
        administrateurs: [procedure.administrateurs.first]
      )
      user.invite!
      user.instructeur
    end

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

    def instructeur_email
      params[:instructeur][:email].strip.downcase
    end
  end
end
