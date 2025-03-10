# frozen_string_literal: true

class DelayedPurgeJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

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

  def delay = Integer(ENV['PURGE_LATER_DELAY_IN_DAY']).day.from_now.to_i.to_s

  # head object to update metadata makes pj unreadable. copy with extra headers
  def soft_delete
    excon_response = client.copy_object(container, key, container, key, { "Content-Type" => blob.content_type, 'X-Delete-At' => delay })
    if excon_response.status != 201
      Sentry.capture_message("Can't expire blob", extra: { key:, headers: })
    else
      service.delete_prefixed("variants/#{key}/") if blob.image?
    end
  end

  def client
    Fog::OpenStack::Storage.new(service.settings)
  end

  def soft_delete_enabled?
    Rails.application.config.active_storage.service == :openstack &&
    delay
  rescue
    false
  end
end
