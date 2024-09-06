# frozen_string_literal: true

class ApplicationVersion
  @@current = nil

  # Detect the current release version, which helps Sentry identifying the current release
  # or can be used as cache key when for some contents susceptible to change between releases.
  #
  # The deploy process can write a "version" file at root
  # containing a string identifying the release, like the sha256 commit used by its release.
  # It defaults to a random string if the file is not found (so each restart will behave like a new version)
  def self.current
    @@current ||= begin
      version = Rails.root.join('version')
      version.readable? ? version.read.strip : SecureRandom.hex
    end
    @@current.presence
  end
end
