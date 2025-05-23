# frozen_string_literal: true

Rails.application.config.active_storage.service_urls_expire_in = 1.hour

Rails.application.config.active_storage.variant_processor = :mini_magick
Rails.application.config.active_storage.analyzers.delete ActiveStorage::Analyzer::ImageAnalyzer
Rails.application.config.active_storage.analyzers.delete ActiveStorage::Analyzer::VideoAnalyzer

ActiveSupport.on_load(:active_storage_blob) do
  include BlobImageProcessorConcern
  include BlobVirusScannerConcern
  include BlobSignedIdConcern

  ActiveStorage::Blob.class_eval do
    def purge_later
      DelayedPurgeJob.perform_later(self)
    end
  end

  def self.generate_unique_secure_token(length: MINIMUM_TOKEN_LENGTH)
    token = super
    "#{Time.current.strftime('%Y/%m/%d')}/#{token[0..1]}/#{token}"
  end
end

ActiveSupport.on_load(:active_storage_attachment) do
  include AttachmentVirusScannerConcern
  include AttachmentImageProcessorConcern
end

Rails.application.reloader.to_prepare do
  class ActiveStorage::BaseJob
    include ActiveJob::RetryOnTransientErrors
  end

  class ActiveStorage::BaseController
    # same store as ApplicationController
    protect_from_forgery with: :exception, store: :cookie
  end
end

# When an OpenStack service is initialized it makes a request to fetch
# `publicURL` to use for all operations. We intercept the method that reads
# this url and replace the host with DS_Proxy host. This way all the operation
# are performed through DS_Proxy.
#
# https://github.com/fog/fog-openstack/blob/37621bb1d5ca78d037b3c56bd307f93bba022ae1/lib/fog/openstack/auth/catalog/v2.rb#L16
require 'fog/openstack/auth/catalog/v2'

module Fog::OpenStack::Auth::Catalog
  class V2
    def endpoint_url(endpoint, interface)
      url = endpoint["#{interface}URL"]

      if interface == 'public'
        publicize(url)
      else
        url
      end
    end

    private

    def publicize(url)
      search = %r{^https://[^/]+/}
      replace = "#{ENV['DS_PROXY_URL']}/"
      url.gsub(search, replace)
    end
  end
end

require 'fog/openstack/auth/catalog/v3'
module Fog::OpenStack::Auth::Catalog
  class V3
    def endpoint_url(endpoint, interface)
      url = endpoint["url"]

      if interface == 'public'
        publicize(url)
      else
        url
      end
    end

    private

    def publicize(url)
      search = %r{^https://[^/]+/}
      replace = "#{ENV['DS_PROXY_URL']}/"
      url.gsub(search, replace)
    end
  end
end
