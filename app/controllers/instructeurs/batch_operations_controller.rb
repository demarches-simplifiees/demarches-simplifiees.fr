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

    private

    def batch_operation_params
      params.require(:batch_operation)
        .permit(:operation, :motivation, :justificatif_motivation, dossier_ids: [])
        .merge(dossier_ids: params['batch_operation']['dossier_ids'].join(',').split(',').uniq)
        .merge(instructeur: current_instructeur)
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
