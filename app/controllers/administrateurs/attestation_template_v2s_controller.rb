module Administrateurs
  class AttestationTemplateV2sController < AdministrateurController
    include UninterlacePngConcern

    before_action :retrieve_procedure, :retrieve_attestation_template, :ensure_feature_active

    def show
      preview_dossier = @procedure.dossier_for_preview(current_user)

      @body = @attestation_template.render_attributes_for(dossier: preview_dossier).fetch(:body)

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
          ['Titre', 'title', :hidden], # only for "title" section, without any action possible
          ['Sous titre', 'heading2', 'h-1'],
          ['Titre de section', 'heading3', 'h-2']
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

      @attestation_template.validate
    end

    def update
      attestation_params = editor_params
      logo_file = attestation_params.delete(:logo)
      signature_file = attestation_params.delete(:signature)

      if logo_file
        attestation_params[:logo] = uninterlace_png(logo_file)
      end

      if signature_file
        attestation_params[:signature] = uninterlace_png(signature_file)
      end

      if @attestation_template.update(attestation_params)
        flash.notice = "Le modèle de l’attestation a été modifié"
      else
        flash.alert = "Le modèle de l’attestation contient des erreurs et n'a pas pu être enregistré. Corriger les erreurs."
      end

      respond_to do |format|
        format.turbo_stream { render :update }
        format.html do
          redirect_to edit_admin_procedure_attestation_template_path(@procedure)
        end
      end
    end

    def create = update

    private

    def ensure_feature_active
      redirect_to root_path if !@procedure.feature_enabled?(:attestation_v2)
    end

    def retrieve_attestation_template
      @attestation_template = @procedure.attestation_template_v2 || @procedure.build_attestation_template_v2(json_body: AttestationTemplate::TIPTAP_BODY_DEFAULT)
    end

    def editor_params
      params.required(:attestation_template).permit(:official_layout, :label_logo, :label_direction, :tiptap_body, :footer, :logo, :signature, :activated)
    end
  end
end
