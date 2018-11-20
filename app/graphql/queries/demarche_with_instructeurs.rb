module Queries
  DemarcheWithInstructeurs = Api::V2::Client.parse <<-'GRAPHQL'
    query($id: ID!) {
      demarche(id: $id) {
        instructeurs {
          id
          email
        }
      }
    }
  GRAPHQL
end
