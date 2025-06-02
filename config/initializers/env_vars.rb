# frozen_string_literal: true

# Ensure that the environment variables defined in the reference env vars file
# are present in the execution environment.
#
# This protects against an out-to-date environment leading to runtime errors.

if ENV['RAILS_ENV'] != 'test' && File.basename($0) != 'rake'
  reference_env_file = File.join('config', 'env.example')
  missings = Dotenv::Environment.new(Rails.root.join(reference_env_file)).filter_map do |key, _value|
    key unless ENV.key?(key.to_s)
  end
  raise "Configuration error: `#{missings.join(',')}` #{missings.size == 1 ? 'is' : 'are'} not present in the process’ environment variables (declared in `#{reference_env_file}`)" if missings.present?
end
