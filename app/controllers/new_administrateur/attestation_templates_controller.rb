module NewAdministrateur
  class AttestationTemplatesController < AdministrateurController
    before_action :retrieve_procedure

    def edit
      @attestation_template = @procedure.attestation_template || AttestationTemplate.new(procedure: @procedure)
    end

    def update
      attestation_template = @procedure.attestation_template
      if attestation_template.update(activated_attestation_params)
        flash.notice = "L'attestation a bien été modifiée"
      else
        flash.alert = attestation_template.errors.full_messages.join('<br>')
      end

      redirect_to edit_admin_procedure_attestation_template_path(@procedure)
    end

    def create
      attestation_template = AttestationTemplate.new(activated_attestation_params.merge(procedure_id: @procedure.id))

      if attestation_template.save
        flash.notice = "L'attestation a bien été sauvegardée"
      else
        flash.alert = attestation_template.errors.full_messages.join('<br>')
      end

      redirect_to edit_admin_procedure_attestation_template_path(@procedure)
    end

    def preview
      attestation = @procedure.attestation_template || AttestationTemplate.new
      @attestation = attestation.render_attributes_for({})

      render 'new_administrateur/attestation_templates/show', formats: [:pdf]
    end

    private

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
        chunky_img = ChunkyPNG::Image.from_io(uploaded_file)
        chunky_img.save(uploaded_file.tempfile.to_path, interlace: false)
        uploaded_file.tempfile.reopen(uploaded_file.tempfile.to_path, 'rb')
      end
      uploaded_file
    end
  end
end
