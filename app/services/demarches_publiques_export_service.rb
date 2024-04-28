# frozen_string_literal: true

class DemarchesPubliquesExportService
  attr_reader :gzip_filename

  def initialize(gzip_filename)
    @gzip_filename = gzip_filename
  end

  def call
    Zlib::GzipWriter.open(gzip_filename) do |gz|
      generate_json(gz)
    end
  end

  private

  def generate_json(io)
    end_cursor = nil
    first = true
    write_array_opening(io)
    loop do
      write_demarches_separator(io) if !first
      execute_query(cursor: end_cursor)
      end_cursor = last_cursor
      io.write(jsonify(demarches))
      first = false
      break if !has_next_page?
    end
    write_array_closing(io)
    io.close
  end

  def execute_query(cursor: nil)
    @graphql_data = SerializerService.demarches_publiques(after: cursor)
  rescue => e
    raise DemarchesPubliquesExportService::Error.new(e.message)
  end

  def last_cursor
    @graphql_data["pageInfo"]["endCursor"]
  end

  def has_next_page?
    @graphql_data["pageInfo"]["hasNextPage"]
  end

  def demarches
    @graphql_data["nodes"]
  end

  def jsonify(demarches)
    demarches.map(&:to_json).join(',')
  end

  def write_array_opening(io)
    io.write('[')
  end

  def write_array_closing(io)
    io.write(']')
  end

  def write_demarches_separator(io)
    io.write(',')
  end
end

class DemarchesPubliquesExportService::Error < StandardError
end
