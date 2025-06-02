# frozen_string_literal: true

module Instructeurs
  class CommentairesController < ApplicationController
    before_action :authenticate_instructeur_or_expert!
    after_action :mark_messagerie_as_read

    def destroy
      if commentaire.sent_by?(current_instructeur) || commentaire.sent_by?(current_expert)
        commentaire.soft_delete!

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

    def commentaire
      @commentaire ||= Dossier
        .find(params[:dossier_id])
        .commentaires
        .find(params[:id])
    end
  end
end
