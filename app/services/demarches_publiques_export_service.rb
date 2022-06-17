class DemarchesPubliquesExportService
  attr_reader :io
  def initialize(io)
    @io = io
  end

  def call
    end_cursor = nil
    first = true
    write_array_opening
    loop do
      write_demarches_separator if !first
      execute_query(cursor: end_cursor)
      end_cursor = last_cursor
      io.write(jsonify(demarches))
      first = false
      break if !has_next_page?
    end
    write_array_closing
    io.close
  end

  private

  def execute_query(cursor: nil)
    result = API::V2::Schema.execute(query, variables: { cursor: cursor }, context: { internal_use: true, admin: true })
    raise DemarchesPubliquesExportService::Error.new(result["errors"]) if result["errors"]
    @graphql_data = result["data"]
  end

  def query
    "query($cursor: String) {
      demarchesPubliques(after: $cursor) {
        pageInfo {
          endCursor
          hasNextPage
        }
        edges {
          node {
            number
            title
            description
            datePublication
            service { nom organisme typeOrganisme }
            cadreJuridique
            deliberation
            dossiersCount
            revision {
              champDescriptors {
                type
                label
                description
                required
                options
                champDescriptors {
                  type
                  label
                  description
                  required
                  options
                }
              }
            }
          }
        }
      }
    }"
  end

  def last_cursor
    @graphql_data["demarchesPubliques"]["pageInfo"]["endCursor"]
  end

  def has_next_page?
    @graphql_data["demarchesPubliques"]["pageInfo"]["hasNextPage"]
  end

  def demarches
    @graphql_data["demarchesPubliques"]["edges"].map { |edge| edge["node"] }
  end

  def jsonify(demarches)
    demarches.map(&:to_json).join(',')
  end

  def write_array_opening
    io.write('[')
  end

  def write_array_closing
    io.write(']')
  end

  def write_demarches_separator
    io.write(',')
  end
end

class DemarchesPubliquesExportService::Error < StandardError
end
