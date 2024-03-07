module Administrateurs
  class AttestationTemplateV2sController < AdministrateurController
    before_action :retrieve_procedure, :retrieve_attestation_template, :ensure_feature_active

    def show
      json_body = @attestation_template.json_body&.deep_symbolize_keys
      @body = TiptapService.to_html(json_body, {})

      respond_to do |format|
        format.html do
          render layout: 'attestation'
        end

        format.pdf do
          html = render_to_string('/administrateurs/attestation_template_v2s/show', layout: 'attestation', formats: [:html])

          result = Typhoeus.post(WEASYPRINT_URL,
                                 headers: { 'content-type': 'application/json' },
                                 body: { html: html }.to_json)

          send_data(result.body, filename: 'attestation.pdf', type: 'application/pdf', disposition: 'inline')
        end
      end
    end

    def edit
    end

    def update
      @attestation_template
        .update(json_body: editor_params)
    end

    private

    def ensure_feature_active
      redirect_to root_path if !@procedure.feature_enabled?(:attestation_v2)
    end

    def retrieve_attestation_template
      @attestation_template = @procedure.attestation_template || @procedure.build_attestation_template
    end

    def editor_params
      params.permit(content: [:type, content: [:type, :text, attrs: [:id, :label]]])
    end
  end
end
