# frozen_string_literal: true

module GroupeInstructeursSignatureConcern
  extend ActiveSupport::Concern

  included do
    def add_signature
      @procedure = procedure
      @groupe_instructeur = groupe_instructeur
      @instructeurs = paginated_instructeurs

      signature_file = params[:groupe_instructeur][:signature]

      if params[:groupe_instructeur].nil? || signature_file.blank?
        if respond_to?(:available_instructeur_emails)
          @available_instructeur_emails = available_instructeur_emails
        end

        flash[:alert] = "Aucun fichier joint pour le tampon de l’attestation"
        render :show
      else
        if @groupe_instructeur.signature.attach(signature_file)
          handle_redirect :success
        else
          handle_redirect :alert
        end
      end
    end

    def preview_attestation_acceptation
      attestation_acceptation_template = procedure.attestation_acceptation_template || procedure.build_attestation_acceptation_template
      @attestation = attestation_acceptation_template.render_attributes_for({ groupe_instructeur: groupe_instructeur })

      render 'administrateurs/attestation_templates/show', formats: [:pdf]
    end

    def preview_attestation_acceptation
      attestation_acceptation_template = procedure.attestation_acceptation_template || procedure.build_attestation_acceptation_template

      if attestation_acceptation_template.version == 2
        preview_service = DossierPreviewService.new(procedure:, current_user:, groupe_instructeur:)
        attributes = attestation_acceptation_template.render_attributes_for(dossier: preview_service.dossier)

        @body = attributes.fetch(:body)
        @signature = attributes.fetch(:signature)
        @attestation_template = attestation_acceptation_template

        html = render_to_string('/administrateurs/attestation_template_v2s/show', layout: 'attestation', formats: [:html])
        pdf = WeasyprintService.generate_pdf(html, procedure_id: procedure.id, path: request.path, user_id: current_user.id)

        send_data(pdf, filename: 'attestation.pdf', type: 'application/pdf', disposition: 'inline')
      else
        @attestation = attestation_acceptation_template.render_attributes_for({ groupe_instructeur: groupe_instructeur })
        render 'administrateurs/attestation_templates/show', formats: [:pdf]
      end
    end

    private

    def handle_redirect(status)
      redirect, preview = if self.class.module_parent_name == "Administrateurs"
        [
          :admin_procedure_groupe_instructeur_path,
          :preview_attestation_acceptation_admin_procedure_groupe_instructeur_path
        ]
      else
        [
          :instructeur_groupe_path,
          :preview_attestation_acceptation_instructeur_groupe_path
        ]
      end

      redirect_path = method(redirect).call(@procedure, @groupe_instructeur)
      preview_path = method(preview).call(@procedure, @groupe_instructeur)

      case status
      when :success
        redirect_to redirect_path, notice: "Le tampon de l’attestation a bien été ajouté. #{helpers.link_to("Prévisualiser l’attestation", preview_path)}"
      when :alert
        redirect_to redirect_path, alert: "Une erreur a empêché l’ajout du tampon. Réessayez dans quelques instants."
      end
    end
  end
end
