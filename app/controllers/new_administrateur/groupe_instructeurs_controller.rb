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
      @available_instructeur_emails = available_instructeur_emails
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
        @available_instructeur_emails = available_instructeur_emails

        flash[:alert] = "le nom « #{label} » est déjà pris par un autre groupe."
        render :show
      end
    end

    def add_instructeur
      emails = params['emails'].presence || []
      emails = emails.map(&:strip).map(&:downcase)

      correct_emails, bad_emails = emails
        .partition { |email| URI::MailTo::EMAIL_REGEXP.match?(email) }

      if bad_emails.present?
        flash[:alert] = t('.wrong_address',
          count: bad_emails.count,
          value: bad_emails.join(', '))
      end

      email_to_adds = correct_emails - groupe_instructeur.instructeurs.pluck(:email)

      if email_to_adds.present?
        instructeurs = email_to_adds.map do |instructeur_email|
          Instructeur.by_email(instructeur_email) ||
            create_instructeur(instructeur_email)
        end

        GroupeInstructeurMailer
          .add_instructeurs(groupe_instructeur, instructeurs, current_user.email)
          .deliver_later

        groupe_instructeur.instructeurs << instructeurs

        flash[:notice] = t('.assignment',
          count: email_to_adds.count,
          value: email_to_adds.join(', '),
          groupe: groupe_instructeur.label)
      end

      redirect_to procedure_groupe_instructeur_path(procedure, groupe_instructeur)
    end

    def remove_instructeur
      if groupe_instructeur.instructeurs.one?
        flash[:alert] = "Suppression impossible : il doit y avoir au moins un instructeur dans le groupe"

      else
        @instructeur = Instructeur.find(instructeur_id)
        groupe_instructeur.instructeurs.destroy(@instructeur)
        flash[:notice] = "L’instructeur « #{@instructeur.email} » a été retiré du groupe."
        GroupeInstructeurMailer
          .remove_instructeur(groupe_instructeur, @instructeur, current_user.email)
          .deliver_later
      end

      redirect_to procedure_groupe_instructeur_path(procedure, groupe_instructeur)
    end

    def update_routing_criteria_name
      procedure.update!(routing_criteria_name: routing_criteria_name)

      redirect_to procedure_groupe_instructeurs_path(procedure),
        notice: "Le libellé est maintenant « #{procedure.routing_criteria_name} »."
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

    def instructeur_id
      params[:instructeur][:id]
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

    def routing_criteria_name
      params[:procedure][:routing_criteria_name]
    end

    def available_instructeur_emails
      all = current_administrateur.instructeurs.pluck(:email)
      assigned = groupe_instructeur.instructeurs.pluck(:email)
      (all - assigned).sort
    end
  end
end
