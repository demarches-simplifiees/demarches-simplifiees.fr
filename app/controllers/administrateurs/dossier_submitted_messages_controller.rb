# frozen_string_literal: true

module Administrateurs
  class DossierSubmittedMessagesController < AdministrateurController
    before_action :retrieve_procedure

    def edit
      @dossier_submitted_message = build_dossier_submitted_message
    end

    def update
      @dossier_submitted_message = build_dossier_submitted_message(dossier_submitted_message_params)

      if @dossier_submitted_message.save
        redirect_to admin_procedure_path(@procedure), flash: { notice: "Les informations de fin de dépot ont bien été sauvegardées." }
      else
        flash.alert = "Impossible de sauvegarder les informations de fin de dépot, veuillez ré-essayer."
        render :edit, status: 400
      end
    end

    def create
      @dossier_submitted_message = build_dossier_submitted_message(dossier_submitted_message_params)
      if @dossier_submitted_message.save
        redirect_to admin_procedure_path(@procedure), flash: { notice: "Les informations de fin de dépot ont bien été sauvegardées." }
      else
        flash.alert = "Impossible de sauvegarder les informations de \"fin de dépot\", veuillez ré-essayer."
        render :edit, status: 400
      end
    end

    private

    # for now, only works on active revision no matter the procedure_revision_policy
    def build_dossier_submitted_message(attributes = {})
      dossier_submitted_message = @procedure.active_revision.dossier_submitted_message || @procedure.active_revision.build_dossier_submitted_message

      dossier_submitted_message.attributes = attributes unless attributes.empty?
      dossier_submitted_message
    end

    def dossier_submitted_message_params
      params.require(:dossier_submitted_message)
        .permit(:message_on_submit_by_usager)
    end
  end
end
