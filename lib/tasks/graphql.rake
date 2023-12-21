require "graphql/rake_task"
GraphQL::RakeTask.new(schema_name: "API::V2::Schema", directory: 'app/graphql')
rule(/^graphql:schema:dump*/) do |t, args|
  Rake::Task[t.name].invoke(*args)
  rake_puts "💥💥💥 HOLY MOLY GUACAMOLE ! 💥💥💥"
  rake_puts "Are you changing the schema.graphql ?"
  rake_puts <<~WARNING
                          ██
                        ██░░██
                      ██░░░░░░██
                    ██░░░░░░░░░░██
                    ██░░░░░░░░░░██
                  ██░░░░░░░░░░░░░░██
                ██░░░░░░██████░░░░░░██
                ██░░░░░░██████░░░░░░██
              ██░░░░░░░░██████░░░░░░░░██
              ██░░░░░░░░██████░░░░░░░░██
            ██░░░░░░░░░░██████░░░░░░░░░░██
          ██░░░░░░░░░░░░██████░░░░░░░░░░░░██
          ██░░░░░░░░░░░░██████░░░░░░░░░░░░██
        ██░░░░░░░░░░░░░░██████░░░░░░░░░░░░░░██
        ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
      ██░░░░░░░░░░░░░░░░██████░░░░░░░░░░░░░░░░██
      ██░░░░░░░░░░░░░░░░██████░░░░░░░░░░░░░░░░██
    ██░░░░░░░░░░░░░░░░░░██████░░░░░░░░░░░░░░░░░░██
    ██░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░██
      ██████████████████████████████████████████
  WARNING
  rake_puts "Please, don't forget to document it in app/graphql/api/v2/stored_query.rb so our dear users will know about it"
end
