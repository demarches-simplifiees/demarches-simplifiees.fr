module Queries
  DemarcheWithDossiers = Api::V2::Client.parse <<-'GRAPHQL'
    query($id: ID!,
      $first: Int,
      $after: String,
      $ids: [ID!],
      $since: ISO8601DateTime) {
      demarche(id: $id) {
        dossiers(first: $first, after: $after, ids: $ids, since: $since) {
          dossiers: nodes {
            ...Queries::DossierFragment
          }
          pagination: pageInfo {
            end_cursor: endCursor
            has_next_page: hasNextPage
          }
        }
      }
    }
  GRAPHQL
end
