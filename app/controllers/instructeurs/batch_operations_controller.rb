# frozen_string_literal: true

module Instructeurs
  class BatchOperationsController < ApplicationController
    before_action :set_procedure
    before_action :ensure_ownership!

    def create
      batch = BatchOperation.safe_create!(batch_operation_params)
      flash[:alert] = "Le traitement de masse n'a pas été lancé. Vérifiez que l'action demandée est possible pour les dossiers sélectionnés" if batch.blank?
      redirect_back(fallback_location: instructeur_procedure_url(@procedure.id))
    end

    def create_batch_avis
      emails = Array(avis_create_params[:emails]).map(&:strip).map(&:downcase).compact_blank
      email_regex = StrictEmailValidator::REGEXP

      invalid_emails = emails.filter { |email| email.present? && !(email =~ email_regex) }

      avis = Avis.new(avis_create_params.except(:emails))
      batch = nil

      if emails.empty? || invalid_emails.any?
        avis.errors.add(:email, :blank) if emails.empty?
        invalid_emails.each { |email| avis.errors.add(:email, "est invalide : #{email}") }
      else
        batch = BatchOperation.safe_create!(batch_operation_avis_params)
      end

      respond_to do |format|
        format.turbo_stream do
          if batch.blank? || avis.errors.any?
            @ids = Array(params.dig(:batch_operation, :dossier_ids)).flat_map do |value|
              value.is_a?(String) ? value.split(',') : value
            end.compact_blank

            render turbo_stream: turbo_stream.replace("modal-avis-batch-form", partial: "shared/avis/form_wrapper",
              locals: {
                url:  create_batch_avis_instructeur_batch_operations_path(procedure_id: @procedure.id),
                linked_dossiers: '',
                must_be_confidentiel: false,
                avis: avis,
                batch_action: true,
                procedure: @procedure,
                dossier_ids: @ids
              })
          else
            render turbo_stream: turbo_stream.append(
              "contenu",
              partial: "shared/avis/redirect_and_close_modal",
              locals: {
                redirect_url: instructeur_procedure_path(@procedure, statut: 'suivis')
              }
            )
          end
        end

        format.html do
          flash[:alert] = "Le traitement de masse n'a pas été lancé. Vérifiez que l'action demandée est possible pour les dossiers sélectionnés" if batch.blank?
          redirect_back(fallback_location: instructeur_procedure_url(@procedure.id))
        end
      end
    end

    private

    def batch_operation_params
      params.require(:batch_operation)
        .permit(:operation, :motivation, :justificatif_motivation, dossier_ids: [])
        .merge(dossier_ids: params['batch_operation']['dossier_ids'].join(',').split(',').uniq)
        .merge(instructeur: current_instructeur)
    end

    def batch_operation_avis_params
      params.require(:batch_operation).permit(dossier_ids: []).tap do |batch_params|
        batch_params[:operation] = 'create_avis'
        batch_params[:instructeur] = current_instructeur
        batch_params.merge!(avis_create_params)
      end
    end

    def avis_create_params
      params.require(:avis).permit(
        :introduction_file,
        :introduction,
        :confidentiel,
        :invite_linked_dossiers,
        :question_label,
        emails: []
      )
    end

    def set_procedure
      @procedure = Procedure.find(params[:procedure_id])
    end

    def ensure_ownership!
      if !current_instructeur.procedures.exists?(@procedure.id)
        flash[:alert] = "Vous n’avez pas accès à cette démarche"
        redirect_to root_path
      end
    end
  end
end
