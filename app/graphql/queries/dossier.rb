module Queries
  Dossier = Api::V2::Client.parse <<-'GRAPHQL'
    query($id: ID!) {
      dossier(id: $id) {
        id
        ...Queries::DossierFragment
      }
    }
  GRAPHQL
end
