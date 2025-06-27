# frozen_string_literal: true

module Instructeurs
  class CommentairesController < ApplicationController
    include InstructeurConcern
    before_action :authenticate_instructeur_or_expert!
    after_action :mark_messagerie_as_read

    def destroy
      retrieve_procedure_presentation if current_instructeur
      if commentaire.sent_by?(current_instructeur) || commentaire.sent_by?(current_expert)
        commentaire.soft_delete!
        set_notifications

        flash.notice = t('.notice')
      else
        flash.alert = t('.alert_acl')
      end
    rescue Discard::RecordNotDiscarded
      # i18n-tasks-use t('instructeurs.commentaires.destroy.alert_already_discarded')
      flash.alert = t('.alert_already_discarded')
    end

    private

    def mark_messagerie_as_read
      if commentaire.sent_by?(current_instructeur)
        current_instructeur.mark_tab_as_seen(commentaire.dossier, :messagerie)
      end
    end

    def dossier
      Dossier.find(params[:dossier_id])
    end

    def commentaire
      @commentaire ||= dossier
        .commentaires
        .find(params[:id])
    end
  end
end
