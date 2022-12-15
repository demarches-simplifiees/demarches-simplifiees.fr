module Administrateurs
  class AttestationTemplatesController < AdministrateurController
    before_action :retrieve_procedure

    def show
      redirect_to edit_admin_procedure_attestation_template_path(@procedure)
    end

    def edit
      @attestation_template = build_attestation_template
    end

    def update
      @attestation_template = @procedure.attestation_template

      if @attestation_template.update(activated_attestation_params)
        flash.notice = "Le modèle de l’attestation a bien été modifié"

        redirect_to edit_admin_procedure_attestation_template_path(@procedure)
      else
        flash.now.alert = "Le modèle de l’attestation contient des erreurs et n'a pas pu être enregistré, veuillez les corriger."

        render :edit
      end
    end

    def create
      @attestation_template = build_attestation_template(activated_attestation_params)

      if @attestation_template.save
        flash.notice = "Le modèle de l’attestation a bien été enregistré"

        redirect_to edit_admin_procedure_attestation_template_path(@procedure)
      else
        flash.now.alert = @attestation_template.errors.full_messages

        render :edit
      end
    end

    def preview
      @attestation = build_attestation_template.render_attributes_for({})

      render 'administrateurs/attestation_templates/show', formats: [:pdf]
    end

    private

    def build_attestation_template(attributes = {})
      attestation_template = @procedure.attestation_template || @procedure.build_attestation_template
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
