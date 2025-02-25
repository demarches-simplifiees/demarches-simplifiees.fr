# frozen_string_literal: true

module Instructeurs
  class RdvsController < InstructeurController
    before_action :set_dossier

    def create
      pending_rdv = @dossier.rdvs.pending.first

      if pending_rdv.present?
        return redirect_to pending_rdv.rdv_plan_url, allow_other_host: true
      end

      @rdv_plan_result = RdvService.new(rdv_connection: current_instructeur.rdv_connection).create_rdv_plan(
        dossier: @dossier,
        first_name: @dossier.individual&.prenom,
        last_name: @dossier.individual&.nom,
        email: @dossier.user_email_for(:notification),
        dossier_url: instructeur_dossier_url(@dossier.procedure, @dossier, host: ENV.fetch("APP_HOST")),
        return_url: rendez_vous_instructeur_dossier_url(@dossier.procedure, @dossier, host: ENV.fetch("APP_HOST"))
      )

      if @rdv_plan_result.success?
        return redirect_to @rdv_plan_result.value!.rdv_plan_url, allow_other_host: true
      end

      Sentry.capture_message("Rdv creation failed", extra: { rdv_plan_result: @rdv_plan_result })

      redirect_to instructeur_dossier_path(@dossier.procedure, @dossier), alert: "Erreur lors de la création du rendez-vous"
    end

    private

    def set_dossier
      @dossier = current_instructeur.dossiers.find(params[:dossier_id])
    end
  end
end
