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
      @buttons = [
        [
          ['Gras', 'bold', 'bold'],
          ['Italic', 'italic', 'italic'],
          ['Souligner', 'underline', 'underline']
        ],
        [
          ['Titre', 'title', 'h-1'],
          ['Sous titre', 'heading2', 'h-2'],
          ['Titre de section', 'heading3', 'h-3']
        ],
        [
          ['Liste à puces', 'bulletList', 'list-unordered'],
          ['Liste numérotée', 'orderedList', 'list-ordered']
        ],
        [
          ['Aligner à gauche', 'left', 'align-left'],
          ['Aligner au centre', 'center', 'align-center'],
          ['Aligner à droite', 'right', 'align-right']
        ],
        [
          ['Undo', 'undo', 'arrow-go-back-line'],
          ['Redo', 'redo', 'arrow-go-forward-line']
        ]
      ]
    end

    def update
      @attestation_template.update!(editor_params)
    end

    private

    def ensure_feature_active
      redirect_to root_path if !@procedure.feature_enabled?(:attestation_v2)
    end

    def retrieve_attestation_template
      @attestation_template = @procedure.attestation_template || @procedure.build_attestation_template
    end

    def editor_params
      params.required(:attestation_template).permit(:tiptap_body)
    end
  end
end
