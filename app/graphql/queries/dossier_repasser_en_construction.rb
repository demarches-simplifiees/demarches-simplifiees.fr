module Queries
  DossierRepasserEnConstruction = Api::V2::Client.parse <<-'GRAPHQL'
    mutation($dossier_id: ID!) {
      payload: dossierRepasserEnConstruction(dossierId: $dossier_id) {
        dossier {
          id
          state
        }
      }
    }
  GRAPHQL
end
