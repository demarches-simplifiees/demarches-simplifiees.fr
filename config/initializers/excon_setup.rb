# frozen_string_literal: true

# needed as ApplicationJob retry on excon error
# and this lib is not explicity loaded by the Gemfile
require 'excon'
