module Instructeurs
  class GroupeInstructeursController < InstructeurController
    include UninterlacePngConcern
    include GroupeInstructeursSignatureConcern

    before_action :ensure_allowed!

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
      instructeur = Instructeur.by_email(instructeur_email) ||
        create_instructeur(instructeur_email)

      if instructeur.blank?
        flash[:alert] = "L’adresse email « #{instructeur_email} » n’est pas valide."
      elsif groupe_instructeur.instructeurs.include?(instructeur)
        flash[:alert] = "L’instructeur « #{instructeur_email} » est déjà dans le groupe."
      else
        groupe_instructeur.add(instructeur)
        flash[:notice] = "L’instructeur « #{instructeur_email} » a été affecté au groupe."

        GroupeInstructeurMailer
          .notify_added_instructeurs(groupe_instructeur, [instructeur], current_user.email)
          .deliver_later
      end

      redirect_to instructeur_groupe_path(procedure, groupe_instructeur)
    end

    def remove_instructeur
      if groupe_instructeur.instructeurs.one?
        flash[:alert] = "Suppression impossible : il doit y avoir au moins un instructeur dans le groupe"
      else
        instructeur = Instructeur.find(instructeur_id)
        if groupe_instructeur.remove(instructeur)
          flash[:notice] = "L’instructeur « #{instructeur.email} » a été retiré du groupe."
          GroupeInstructeurMailer
            .notify_removed_instructeur(groupe_instructeur, instructeur, current_user.email)
            .deliver_later
        else
          flash[:alert] = "L’instructeur « #{instructeur.email} » n’est pas dans le groupe."
        end
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

      user.invite! if user.valid?
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

    def instructeur_id
      params[:instructeur][:id]
    end

    def ensure_allowed!
      if !(current_administrateur&.owns?(procedure) || procedure.instructeurs_self_management_enabled?)
        flash[:alert] = "Vous n’avez pas le droit de gérer les instructeurs de cette démarche"
        redirect_to instructeur_procedure_path(procedure)
      end
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "Vous n’avez pas accès à cette démarche"
      redirect_to root_path
    end
  end
end
