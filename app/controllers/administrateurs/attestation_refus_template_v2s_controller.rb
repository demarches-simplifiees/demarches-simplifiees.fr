# frozen_string_literal: true

module Administrateurs
  class AttestationRefusTemplateV2sController < AdministrateurController
    before_action :retrieve_procedure
    before_action :preload_revisions

    def show
      redirect_to edit_admin_procedure_attestation_refus_template_v2_path(@procedure)
    end

    def edit
      @attestation_refus_template = attestation_refus_template
    end

    def update
      @attestation_refus_template = attestation_refus_template

      if @attestation_refus_template.update(attestation_refus_template_params)
        flash.notice = "Le modèle de l'attestation de refus a bien été modifié"

        redirect_to edit_admin_procedure_attestation_refus_template_v2_path(@procedure)
      else
        flash.now.alert = "Le modèle de l'attestation de refus contient des erreurs et n'a pas pu être enregistré. Veuillez les corriger"

        render :edit
      end
    end

    def create
      @attestation_refus_template = attestation_refus_template
      @attestation_refus_template.assign_attributes(attestation_refus_template_params)

      if @attestation_refus_template.save
        flash.notice = "Le modèle de l'attestation de refus a bien été enregistré"

        redirect_to edit_admin_procedure_attestation_refus_template_v2_path(@procedure)
      else
        flash.now.alert = @attestation_refus_template.errors.full_messages

        render :edit
      end
    end

    def preview
      @attestation_refus_template = attestation_refus_template
      attributes = @attestation_refus_template.render_attributes_for(attestation_refus_template_params.except(:json_body))

      respond_to do |format|
        format.pdf do
          html = render_to_string('/administrateurs/attestation_refus_template_v2s/show', layout: 'attestation', formats: [:html], assigns: {
                                    attestation_template: @attestation_refus_template,
                                    body: attributes.fetch(:body),
                                    signature: attributes.fetch(:signature)
                                  })

          render pdf: 'attestation',
                 content: WeasyprintService.generate_pdf(html, { procedure_id: @procedure.id, dossier_id: 'apercu' }),
                 disposition: 'inline'
        end
      end
    end

    private

    def attestation_refus_template
      @attestation_refus_template ||= @procedure.attestation_refus_templates_v2.first || @procedure.attestation_refus_templates_v2.build(
        version: 2,
        json_body: AttestationRefusTemplate::TIPTAP_BODY_DEFAULT
      )
    end

    def attestation_refus_template_params
      params.require(:attestation_refus_template).permit(:footer, :activated, :logo, :signature, :json_body)
    end
  end
end