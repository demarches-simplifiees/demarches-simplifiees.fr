namespace :graphql do
  task dump_schema: :environment do
    # Get a string containing the definition in GraphQL IDL:
    schema_defn = Api::V2::Schema.to_definition
    # Choose a place to write the schema dump:
    schema_path = "app/graphql/schema.graphql"
    # Choose a place to write the docs:
    docs_path = "public/docs/graphql"
    # Write the schema dump to that file:
    File.write(Rails.root.join(schema_path), "#{schema_defn}\n")
    # Write the docs:
    GraphQLDocs.build(schema: schema_defn,
      delete_output: true,
      output_dir: Rails.root.join(docs_path),
      base_url: '/docs/graphql')
    puts "Updated #{schema_path} and #{docs_path}"
  end
end
