# frozen_string_literal: true

SimpleCov.start "rails" do
  enable_coverage :branch

  command_name "RSpec process #{Process.pid}"

  if ENV["CI"] # codecov compatibility
    require 'simplecov-cobertura'
    formatter SimpleCov::Formatter::CoberturaFormatter
  else
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::SimpleFormatter,
      SimpleCov::Formatter::HTMLFormatter
    ])
  end

  add_filter "/channels/" # not used
  groups.delete("Channels")

  add_filter "/lib/tasks/deployment/"

  add_group "Components", "app/components"
  add_group "API", ["app/graphql", "app/serializers"]
  add_group "Manager", ["app/dashboards", "app/fields", "app/controllers/manager"]
  add_group "Models", ["app/models", "app/validators"]
  add_group "Policies", "app/policies"
  add_group "Services", "app/services"
  add_group "Tasks", ["app/tasks", "lib/tasks"]
end
