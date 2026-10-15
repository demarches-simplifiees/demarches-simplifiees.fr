# frozen_string_literal: true

module Manager
  class ConfirmationUrlsController < Manager::ApplicationController
    include AdministrateurAlreadyAddedConcern

    before_action :ensure_administrateur_exists
    before_action :ensure_not_already_added

    def new
      @url = new_manager_procedure_administrateur_confirmation_url(
        procedure.id,
        q: encrypt({ email: params[:email], inviter_id: current_super_admin.id, procedure_id: procedure.id })
      )
    end

    private

    def ensure_administrateur_exists
      redirect("Cet administrateur n’existe pas. Veuillez réessayer.") unless administrateur
    end

    def redirect(alert)
      flash[:alert] = alert
      redirect_to manager_procedure_path(procedure)
    end

    def administrateur
      @administrateur ||= Administrateur.by_email(params[:email])
    end

    def procedure
      @procedure ||= Procedure.with_discarded.find(params[:procedure_id])
    end

    def encrypt(parameters)
      message_encryptor_service.encrypt_and_sign(parameters, purpose: :confirm_adding_administrateur)
    end
  end
end
