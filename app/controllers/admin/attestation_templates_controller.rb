class Admin::AttestationTemplatesController < AdminController
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

  def disactivate
    attestation_template = @procedure.attestation_template
    attestation_template.activated = false
    attestation_template.save

    flash.notice = "L'attestation a bien été désactivée"

    redirect_to edit_admin_procedure_attestation_template_path(@procedure)
  end

  def preview
    @title      = activated_attestation_params[:title]
    @body       = activated_attestation_params[:body]
    @footer     = activated_attestation_params[:footer]
    @created_at = Time.zone.now

    # In a case of a preview, when the user does not change its images,
    # the images are not uploaded and thus should be retrieved from previous
    # attestation_template
    @logo = activated_attestation_params[:logo] || @procedure.attestation_template&.logo
    @signature = activated_attestation_params[:signature] || @procedure.attestation_template&.signature

    render 'admin/attestation_templates/show', formats: [:pdf]
  end

  def delete_logo
    attestation_template = @procedure.attestation_template

    attestation_template.remove_logo!
    attestation_template.save

    flash.notice = 'le logo a bien été supprimée'
    redirect_to edit_admin_procedure_attestation_template_path(@procedure)
  end

  def delete_signature
    attestation_template = @procedure.attestation_template

    attestation_template.remove_signature!
    attestation_template.save

    flash.notice = 'la signature a bien été supprimée'
    redirect_to edit_admin_procedure_attestation_template_path(@procedure)
  end

  private

  def activated_attestation_params
    # cache result to avoid multiple uninterlaced computations
    if @activated_attestation_params.nil?
      @activated_attestation_params = params.require(:attestation_template)
        .permit(:title, :body, :footer, :signature)
        .merge(activated: true)

      @activated_attestation_params[:logo] = uninterlaced_png(params['attestation_template']['logo'])
      @activated_attestation_params[:signature] = uninterlaced_png(params['attestation_template']['signature'])
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
