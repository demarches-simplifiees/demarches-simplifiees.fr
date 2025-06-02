# frozen_string_literal: true

module Mutations
  class DossierAjouterInstructeur < Mutations::BaseMutation
    include DossierHelper

    description "Ajouter un instructeur au dossier de la part d'un autre instructeur"

    argument :sender_instructeur_id, ID, "instructeur expéditeur", required: true, loads: Types::ProfileType
    argument :dossier_id, ID, "Dossier ID", required: true, loads: Types::DossierType
    argument :recipient_instructeur_id, ID, "instructeur à affecter", required: true, loads: Types::ProfileType

    field :dossier, Types::DossierType, null: true
    field :errors, [Types::ValidationErrorType], null: true

    def resolve(sender_instructeur:, dossier:, recipient_instructeur:)
      recipient_instructeur.follow(dossier)
      InstructeurMailer.send_dossier(sender_instructeur, dossier, recipient_instructeur).deliver_later

      { dossier: dossier }
    end

    def authorized?(sender_instructeur:, dossier:, recipient_instructeur:)
      groupe = dossier.groupe_instructeur
      instructeurs = [sender_instructeur, recipient_instructeur]
      if groupe.present?
        instructeurs.each do |instructeur|
          return false, { errors: ["L'instructeur '#{instructeur.email}' ne fait pas partie du groupe d'instructeurs '#{groupe.label}'"] } if !groupe.instructeurs.include?(instructeur)
        end
      else
        return false, { errors: ["Le dossier doit d'abord être affecté à un groupe d'instructeur"] }
      end
      true
    end
  end
end
