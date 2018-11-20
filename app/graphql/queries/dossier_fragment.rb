module Queries
  DossierFragment = Api::V2::Client.parse <<-'GRAPHQL'
    fragment on Dossier {
      id
      state
      created_at: createdAt
      updated_at: updatedAt
      usager {
        id
        email
      }
      instructeurs {
        id
        email
      }
    }
  GRAPHQL
end
