require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true, net_http_connect_on_start: true)
