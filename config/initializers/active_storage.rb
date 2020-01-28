Rails.application.config.active_storage.service_urls_expire_in = 1.hour

# In Rails 5.2, we have to hook at `on_load` on the blob themeselves, which is
# not ideal.
#
# Rails 6 adds support for `.on_load(:active_storage_attachment)`, which is
# cleaner (as it allows to enqueue the virus scan on attachment creation, rather
# than on blob creation).
ActiveSupport.on_load(:active_storage_blob) do
  include BlobSignedIdConcern
  include BlobVirusScannerConcern
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
