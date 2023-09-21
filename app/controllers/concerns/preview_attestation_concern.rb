module PreviewAttestationConcern
  extend ActiveSupport::Concern

  included do
    def preview_attestation
      attestation_template = procedure.attestation_template || procedure.build_attestation_template
      @attestation = attestation_template.render_attributes_for({ groupe_instructeur: groupe_instructeur })

      render 'administrateurs/attestation_templates/show', formats: [:pdf]
    end
  end
end
