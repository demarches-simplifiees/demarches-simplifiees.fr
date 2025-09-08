# frozen_string_literal: true

class StagingAuthService
  def self.authenticate(username, password)
    if enabled?
      username == ENV.fetch("BASIC_AUTH_USERNAME") && password == ENV.fetch("BASIC_AUTH_PASSWORD")
    else
      true
    end
  end

  def self.enabled? = ENV.enabled?("BASIC_AUTH")
end
