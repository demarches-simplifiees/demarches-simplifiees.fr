module Queries
  DossierClasserSansSuite = Api::V2::Client.parse <<-'GRAPHQL'
    mutation($dossier_id: ID!, $motivation: String!) {
      payload: dossierClasserSansSuite(dossierId: $dossier_id, motivation: $motivation) {
        dossier {
          id
          state
        }
      }
    }
  GRAPHQL
end
