module Queries
  Demarche = Api::V2::Client.parse <<-'GRAPHQL'
    query($id: ID!) {
      demarche(id: $id) {
        id
        state
        title
        description
        created_at: createdAt
        updated_at: updatedAt
        archived_at: archivedAt
        instructeurs {
          id
          email
        }
      }
    }
  GRAPHQL
end
