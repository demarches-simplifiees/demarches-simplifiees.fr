module Gestionnaires
  class GroupeGestionnaireCommentairesController < GestionnaireController
    before_action :retrieve_groupe_gestionnaire
    before_action :retrieve_last_commentaire, only: [:show, :create, :destroy]

    def index
    end

    def show
      @commentaire_seen_at = current_gestionnaire.commentaire_seen_at(@groupe_gestionnaire, @last_commentaire.sender_id, @last_commentaire.sender_type)
      @commentaire = CommentaireGroupeGestionnaire.new
      current_gestionnaire.mark_commentaire_as_seen(@groupe_gestionnaire, @last_commentaire.sender_id, @last_commentaire.sender_type)
    end

    def create
      @commentaire = @groupe_gestionnaire.commentaire_groupe_gestionnaires.create(commentaire_params.merge(sender_id: @last_commentaire.sender_id, sender_type: @last_commentaire.sender_type, gestionnaire: current_gestionnaire))

      if @commentaire.errors.empty?
        GroupeGestionnaireMailer.notify_new_commentaire_groupe_gestionnaire(@groupe_gestionnaire, @commentaire, current_gestionnaire.email, @commentaire.sender_email, admin_groupe_gestionnaire_commentaires_path).deliver_later
        flash.notice = "Message envoyé"
        current_gestionnaire.mark_commentaire_as_seen(@groupe_gestionnaire, @commentaire.sender_id, @commentaire.sender_type)
        redirect_to gestionnaire_groupe_gestionnaire_commentaire_path(@groupe_gestionnaire, @commentaire)
      else
        flash.alert = @commentaire.errors.full_messages
        render :show
      end
    end

    def destroy
      if @last_commentaire.soft_deletable?(current_gestionnaire)
        @last_commentaire.soft_delete!
        @commentaire_seen_at = current_gestionnaire.commentaire_seen_at(@groupe_gestionnaire, @last_commentaire.sender_id, @last_commentaire.sender_type)

        flash.notice = t('.notice')
      else
        flash.alert = t('.alert_acl')
      end
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
