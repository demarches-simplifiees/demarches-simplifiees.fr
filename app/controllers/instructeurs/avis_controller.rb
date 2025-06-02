# frozen_string_literal: true

module Instructeurs
  class AvisController < InstructeurController
    include CreateAvisConcern

    before_action :authenticate_instructeur!
    A_DONNER_STATUS = 'a-donner'
    DONNES_STATUS   = 'donnes'

    def revoquer
      avis = Avis.find(params[:id])
      if avis.revoke_by!(current_instructeur)
        flash.notice = "#{avis.expert.email} ne peut plus donner son avis sur ce dossier."
        redirect_back(fallback_location: avis_instructeur_dossier_path(avis.procedure, avis.dossier))
      end
    end

    def remind
      avis = Avis.find(params[:id])
      if avis.remind_by!(current_instructeur)
        AvisMailer.avis_invitation(avis).deliver_later
        flash.notice = "Un mail de relance a été envoyé à #{avis.expert.email}"
        redirect_back(fallback_location: avis_instructeur_dossier_path(avis.procedure, avis.dossier))
      end
    end
  end
end
