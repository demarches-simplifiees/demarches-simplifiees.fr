# frozen_string_literal: true

class DelayedPurgeJob < ApplicationJob
  queue_as :low

  # when storage is down, errors come in a variety of forms
  with_options(wait: :polynomially_longer) do
    retry_on Excon::Error::BadGateway
    retry_on Excon::Error::ServiceUnavailable
    retry_on Excon::Error::InternalServerError
    retry_on Excon::Error::Timeout
    retry_on Excon::Error::RequestTimeout
    retry_on Excon::Error::ServiceUnavailable
  end

  # rate limit reached
  retry_on Excon::Error::TooManyRequests, wait: 10.minutes

  # can discard
  discard_on ActiveRecord::RecordNotFound

  def self.openstack?
    Rails.application.config.active_storage.service == :openstack
  end

  if openstack?
    require 'fog/openstack'
    discard_on Fog::OpenStack::Storage::NotFound
  end

  delegate :service, :key, to: :blob
  delegate :container, to: :service

  attr_reader :blob

  def perform(blob)
    @blob = blob
    if !soft_delete_enabled?
      blob.purge
    else
      soft_delete
    end
  end

  private

  def delay = Integer(ENV['PURGE_LATER_DELAY_IN_DAY']).day.from_now.to_i

  # head object to update metadata makes pj unreadable. copy with extra headers
  def soft_delete
    # ActiveStorage removes attachments first and then calls purge (or purge_later) on the blob.
    # In a before_destroy hook, it checks if any attachments still exist. If no attachments are left, it deletes the blob.
    # We should replicate the same behavior here.
    # https://github.com/rails/rails/blob/ef88965e8a0c72496c210a5a0a48b85ec9a2ed17/activestorage/app/models/active_storage/blob.rb#L53-L55
    return if blob.attachments.exists?
    excon_response = client.copy_object(container, key, container, key, { "Content-Type" => blob.content_type, 'X-Delete-At' => delay.to_s })
    if excon_response.status != 201
      Sentry.capture_message("Can't expire blob", extra: { key:, headers: })
    else
      service.delete_prefixed("variants/#{key}/") if blob.image?
    end
  end

  def soft_delete_enabled?
    DelayedPurgeJob.openstack? && delay.positive?
  rescue
    false
  end

  def client
    ActiveStorage::Blob.service.send(:client)
  end
end
