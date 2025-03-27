# frozen_string_literal: true

class DelayedPurgeJob < ApplicationJob
  queue_as :low

  # when storage is down, errors come in a variety of forms
  with_options(wait: :exponentially_longer) do
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
    OpenStackStorage.with_client do |client|
      excon_response = client.copy_object(container, key, container, key, { "Content-Type" => blob.content_type, 'X-Delete-At' => delay.to_s })
      if excon_response.status != 201
        Sentry.capture_message("Can't expire blob", extra: { key:, headers: })
      else
        service.delete_prefixed("variants/#{key}/") if blob.image?
      end
    end
  end

  def soft_delete_enabled?
    DelayedPurgeJob.openstack? && delay.positive?
  rescue
    false
  end
end
