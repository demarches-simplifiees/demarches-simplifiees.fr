module Administrateurs
  class AttestationTemplatesController < AdministrateurController
    before_action :retrieve_procedure

    def edit
      @attestation_template = build_attestation
    end

    def update
      attestation_template = @procedure.draft_attestation_template.find_or_revise!

      if attestation_template.update(activated_attestation_params)
        AttestationTemplate
          .where(id: @procedure.revisions.pluck(:attestation_template_id).compact)
          .update_all(activated: attestation_template.activated?)

        flash.notice = "L'attestation a bien été modifiée"
      else
        flash.alert = attestation_template.errors.full_messages.join('<br>')
      end

      redirect_to edit_admin_procedure_attestation_template_path(@procedure)
    end

    def create
      attestation_template = build_attestation(activated_attestation_params)

      if attestation_template.save
        if @procedure.publiee? && !@procedure.feature_enabled?(:procedure_revisions)
          # If revisions support is not enabled and procedure is published
          # attach the same attestation template to published revision.
          @procedure.published_revision.update(attestation_template: attestation_template)
        end
        flash.notice = "L'attestation a bien été sauvegardée"
      else
        flash.alert = attestation_template.errors.full_messages.join('<br>')
      end

      redirect_to edit_admin_procedure_attestation_template_path(@procedure)
    end

    def preview
      attestation_template = build_attestation
      @attestation = attestation_template.render_attributes_for({})

      render 'administrateurs/attestation_templates/show', formats: [:pdf], locals: attestation_template.version(@procedure)
    end

    private

    def build_attestation(attributes = {})
      attestation_template = @procedure.draft_attestation_template || @procedure.draft_revision.build_attestation_template
      attestation_template.attributes = attributes
      attestation_template
    end

    def activated_attestation_params
      # cache result to avoid multiple uninterlaced computations
      if @activated_attestation_params.nil?
        @activated_attestation_params = params.require(:attestation_template)
          .permit(:title, :body, :footer, :activated, :logo, :signature)

        logo_file = params['attestation_template'].delete('logo')
        signature_file = params['attestation_template'].delete('signature')

        if logo_file.present?
          @activated_attestation_params[:logo] = uninterlaced_png(logo_file)
        end
        if signature_file.present?
          @activated_attestation_params[:signature] = uninterlaced_png(signature_file)
        end
      end

      @activated_attestation_params
    end

    def uninterlaced_png(uploaded_file)
      if uploaded_file&.content_type == 'image/png'
        chunky_img = ChunkyPNG::Image.from_io(uploaded_file.to_io)
        chunky_img.save(uploaded_file.tempfile.to_path, interlace: false)
        uploaded_file.tempfile.reopen(uploaded_file.tempfile.to_path, 'rb')
      end
      uploaded_file
    end
  end
end
