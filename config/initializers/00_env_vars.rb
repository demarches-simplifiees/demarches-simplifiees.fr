# frozen_string_literal: true

# Ensure that the environment variables defined in the reference env vars file
# are present in the execution environment.
#
# This protects against an out-to-date environment leading to runtime errors.

if ENV['RAILS_ENV'] != 'test' && File.basename($0) != 'rake'
  reference_env_file = File.join('config', 'env.example')
  Dotenv::Environment.new(Rails.root.join(reference_env_file)).each do |key, _value|
    if !ENV.key?(key.to_s)
      raise "Configuration error: `#{key}` is not present in the process’ environment variables (declared in `#{reference_env_file}`)"
    end
  end
end

def ENV.enabled?(name)
  value = ENV["#{name}_ENABLED"] || ENV[name] || ""
  value.downcase.in?(["enabled", "yes", "true", "1"])
end
