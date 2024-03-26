module Gestionnaires
  class GroupeGestionnaireCommentairesController < GestionnaireController
    before_action :retrieve_groupe_gestionnaire
    before_action :retrieve_last_commentaire, only: [:show, :create, :destroy]

    def index
    end

    def show
      @commentaire = CommentaireGroupeGestionnaire.new
    end

    def create
      @commentaire = @groupe_gestionnaire.commentaire_groupe_gestionnaires.create(commentaire_params.merge(sender: @last_commentaire.sender, gestionnaire: current_gestionnaire))

      if @commentaire.errors.empty?
        flash.notice = "Message envoyé"
        redirect_to gestionnaire_groupe_gestionnaire_commentaire_path(@groupe_gestionnaire, @commentaire)
      else
        flash.alert = @commentaire.errors.full_messages
        render :show
      end
    end

    def destroy
      if @last_commentaire.soft_deletable?(current_gestionnaire)
        @last_commentaire.soft_delete!

        flash.notice = t('.notice')
      else
        flash.alert = t('.alert_acl')
      end
      # redirect_to gestionnaire_groupe_gestionnaire_commentaire_path(@groupe_gestionnaire, @last_commentaire)
    rescue Discard::RecordNotDiscarded
      flash.alert = t('.alert_already_discarded')
    end

    private

    def retrieve_last_commentaire
      @last_commentaire = @groupe_gestionnaire.commentaire_groupe_gestionnaires.find(params[:id])
    end

    def commentaire_params
      params.require(:commentaire_groupe_gestionnaire).permit(:body)
    end
  end
end
