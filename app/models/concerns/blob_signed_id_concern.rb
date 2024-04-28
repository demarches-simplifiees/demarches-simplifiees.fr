# frozen_string_literal: true

module BlobSignedIdConcern
  extend ActiveSupport::Concern

  included do
    # We override signed_id to add `expires_in` option to generated hash.
    # This is a measure to ensure that we never under any circumstance
    # expose permanent attachment url
    def signed_id(**options)
      ActiveStorage.verifier.generate(id, **options, purpose: :blob_id, expires_in: Rails.application.config.active_storage.service_urls_expire_in)
    end
  end
end
