# frozen_string_literal: true

require 'fog/openstack'
require 'connection_pool'

module OpenStackStorage
  def self.client_pool
    @client_pool ||= ConnectionPool.new(size: 3, timeout: 3) do
      if Rails.application.config.active_storage.service == :openstack
        credentials = Rails.application.config.active_storage
          .service_configurations['openstack']['credentials']

        Fog::OpenStack::Storage.new(credentials)
      end
    end
  end

  def self.with_client(&block)
    client_pool.with(&block)
  end
end
