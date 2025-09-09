# frozen_string_literal: true

module Administrateurs
  class AttestationRefusTemplatesController < AdministrateurController
    before_action :retrieve_procedure
    before_action :preload_revisions

    def show
      redirect_to edit_admin_procedure_attestation_refus_template_path(@procedure)
    end

    def edit
      @attestation_refus_template = build_attestation_refus_template
      @attestation_refus_template.validate
    end

    def update
      @attestation_refus_template = @procedure.attestation_refus_template_v1

      if @attestation_refus_template.update(activated_attestation_refus_params)
        flash.notice = "Le modèle de l'attestation de refus a bien été modifié"

        redirect_to edit_admin_procedure_attestation_refus_template_path(@procedure)
      else
        flash.now.alert = "Le modèle de l'attestation de refus contient des erreurs et n'a pas pu être enregistré. Veuillez les corriger"

        render :edit
      end
    end

    def create
      @attestation_refus_template = build_attestation_refus_template(activated_attestation_refus_params)

      if @attestation_refus_template.save
        flash.notice = "Le modèle de l'attestation de refus a bien été enregistré"

        redirect_to edit_admin_procedure_attestation_refus_template_path(@procedure)
      else
        flash.now.alert = @attestation_refus_template.errors.full_messages

        render :edit
      end
    end

    def preview
      @attestation = build_attestation_refus_template.render_attributes_for({})

      render 'administrateurs/attestation_refus_templates/show', formats: [:pdf]
    end

    private

    def build_attestation_refus_template(attributes = {})
      attestation_refus_template = @procedure.attestation_refus_template_v1 || @procedure.build_attestation_refus_template_v1
      attestation_refus_template.attributes = attributes
      attestation_refus_template
    end

    def activated_attestation_refus_params
      # cache result to avoid multiple uninterlaced computations
      if @activated_attestation_refus_params.nil?
        @activated_attestation_refus_params = params.require(:attestation_refus_template)
          .permit(:title, :body, :footer, :activated, :logo, :signature)
      end

      @activated_attestation_refus_params
    end
  end
end