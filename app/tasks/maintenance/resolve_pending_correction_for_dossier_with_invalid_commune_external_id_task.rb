# frozen_string_literal: true

module Maintenance
  class ResolvePendingCorrectionForDossierWithInvalidCommuneExternalIdTask < MaintenanceTasks::Task
    DEFAULT_INSTRUCTEUR_EMAIL = ENV.fetch('DEFAULT_INSTRUCTEUR_EMAIL') { CONTACT_EMAIL }

    no_collection

    def process
      DossierCorrection.joins(:commentaire)
        .where(commentaire: { instructeur_id: current_instructeur.id })
        .where(resolved_at: nil)
        .find_each do |dossier_correction|
          penultimate_traitement, last_traitement = *dossier_correction.dossier.traitements.last(2)
          dossier_correction.resolve!

          if last_traitement_by_us?(last_traitement) && last_transition_to_en_construction?(last_traitement, penultimate_traitement)
            dossier_correction.dossier.passer_en_instruction(instructeur: current_instructeur) if dossier_correction.dossier.validate(:champs_public_value)
          end
        end
    end

    def current_instructeur
      @current_instructeur = User.find_by(email: DEFAULT_INSTRUCTEUR_EMAIL).instructeur
    end

    def current_instructeur_id
      current_instructeur.id
    end

    def current_instructeur_email
      current_instructeur.email
    end

    def last_traitement_by_us?(traitement)
      traitement.instructeur_email == DEFAULT_INSTRUCTEUR_EMAIL
    end

    def last_transition_to_en_construction?(last_traitement, penultimate_traitement)
      last_traitement.state == "en_construction" && penultimate_traitement.state == 'en_instruction'
    end
  end
end
