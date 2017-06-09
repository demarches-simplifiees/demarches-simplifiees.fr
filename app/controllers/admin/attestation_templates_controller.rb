class Admin::AttestationTemplatesController < AdminController
  before_action :retrieve_procedure

  def edit
    @attestation_template = @procedure.attestation_template || AttestationTemplate.new(procedure: @procedure)
  end

  def update
    attestation_template = @procedure.attestation_template

    if attestation_template.update_attributes(activated_attestation_params)
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

  private

  def activated_attestation_params
    params.require(:attestation_template)
      .permit(:title, :body, :footer, :logo, :signature)
      .merge(activated: true)
  end
end
