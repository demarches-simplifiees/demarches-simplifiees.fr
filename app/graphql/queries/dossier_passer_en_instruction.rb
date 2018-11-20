module Queries
  DossierPasserEnInstruction = Api::V2::Client.parse <<-'GRAPHQL'
    mutation($dossier_id: ID!, $instructeur_id: ID!) {
      payload: dossierPasserEnInstruction(dossierId: $dossier_id, instructeurId: $instructeur_id) {
        dossier {
          id
          state
        }
      }
    }
  GRAPHQL
end
