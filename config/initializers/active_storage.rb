ActiveStorage::Service.url_expires_in = 1.hour

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
# https://github.com/fog/fog-openstack/blob/79116756ab04058a4bd970f3f1944886210221ed/lib/fog/openstack/auth/catalog/v3.rb#L16
require 'fog/openstack/auth/catalog/v3'
module Fog::OpenStack::Auth::Catalog
  class V3
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
