module Administrateurs
  class AttestationTemplateV2sController < AdministrateurController
    before_action :retrieve_procedure, :retrieve_attestation_template

    def show
      json_body = @attestation_template.json_body&.deep_symbolize_keys
      @body = TiptapService.to_html(json_body, {})

      render layout: 'attestation'
    end

    def edit
    end

    def update
      @attestation_template
        .update(json_body: editor_params)
    end

    private

    def retrieve_attestation_template
      @attestation_template = @procedure.attestation_template || @procedure.build_attestation_template
    end

    def editor_params
      params.permit(content: [:type, content: [:type, :text, attrs: [:id, :label]]])
    end
  end
end
