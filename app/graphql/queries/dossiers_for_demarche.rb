module Queries
  DossiersForDemarche = Api::V2::Client.parse <<-'GRAPHQL'
    query($id: ID!, $since: ISO8601DateTime, $after: String, $before: String) {
      demarche(id: $id) {
        dossiers(first: 50, since: $since, after: $after, before: $before) {
          data: nodes {
            id
            ...Queries::DossierFragment
          }
          meta: pageInfo {
            end_cursor: endCursor
            has_next_page: hasNextPage
            has_previous_page: hasPreviousPage
            start_cursor: startCursor
          }
        }
      }
    }
  GRAPHQL
end
