module Administrateurs
  class GroupeGestionnaireController < AdministrateurController
    before_action :retrieve_groupe_gestionnaire, only: [:show, :administrateurs, :gestionnaires, :commentaires, :create_commentaire]

    def show
    end

    def administrateurs
    end

    def gestionnaires
    end

    def commentaires
      @commentaire = CommentaireGroupeGestionnaire.new
    end

    def create_commentaire
      @commentaire = @groupe_gestionnaire.commentaire_groupe_gestionnaires.create(commentaire_params.merge(sender: current_administrateur))

      if @commentaire.errors.empty?
        flash.notice = "Message envoyé"
        redirect_to admin_groupe_gestionnaire_commentaires_path
      else
        flash.alert = @commentaire.errors.full_messages
        render :commentaires
      end
    end

    private

    def retrieve_groupe_gestionnaire
      id = current_administrateur.groupe_gestionnaire_id
      @groupe_gestionnaire = GroupeGestionnaire.find(id)

      Sentry.configure_scope do |scope|
        scope.set_tags(groupe_gestionnaire: @groupe_gestionnaire.id)
      end
    rescue ActiveRecord::RecordNotFound
      flash.alert = 'Groupe inexistant'
      redirect_to admin_procedures_path, status: 404
    end

    def commentaire_params
      params.require(:commentaire_groupe_gestionnaire).permit(:body)
    end
  end
end
