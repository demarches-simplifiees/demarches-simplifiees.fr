module NewAdministrateur
  class GroupeInstructeursController < AdministrateurController
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

    def create
      @groupe_instructeur = procedure
        .groupe_instructeurs
        .new(label: label, instructeurs: [current_administrateur.instructeur])

      if @groupe_instructeur.save
        redirect_to procedure_groupe_instructeur_path(procedure, @groupe_instructeur),
          notice: "Le groupe d’instructeurs « #{label} » a été créé."
      else
        @procedure = procedure
        @groupes_instructeurs = paginated_groupe_instructeurs

        flash[:alert] = "le nom « #{label} » est déjà pris par un autre groupe."
        render :index
      end
    end

    def update
      @groupe_instructeur = groupe_instructeur

      if @groupe_instructeur.update(label: label)
        redirect_to procedure_groupe_instructeur_path(procedure, groupe_instructeur),
          notice: "Le nom est à présent « #{label} »."
      else
        @procedure = procedure
        @instructeurs = paginated_instructeurs

        flash[:alert] = "le nom « #{label} » est déjà pris par un autre groupe."
        render :show
      end
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

      redirect_to procedure_groupe_instructeur_path(procedure, groupe_instructeur)
    end

    private

    def create_instructeur(email)
      user = User.create_or_promote_to_instructeur(
        email,
        SecureRandom.hex,
        administrateurs: [current_administrateur]
      )
      user.invite!
      user.instructeur
    end

    def procedure
      current_administrateur
        .procedures
        .includes(:groupe_instructeurs)
        .find(params[:procedure_id])
    end

    def groupe_instructeur
      procedure.groupe_instructeurs.find(params[:id])
    end

    def instructeur_email
      params[:instructeur][:email].strip.downcase
    end

    def label
      params[:groupe_instructeur][:label]
    end

    def paginated_groupe_instructeurs
      procedure
        .groupe_instructeurs
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
