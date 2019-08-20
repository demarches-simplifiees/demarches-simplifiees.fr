class IPService
  class << self
    def ip_trusted?(ip)
      ip_address = parse_address(ip)

      trusted_networks.any? { |network| network.include?(ip_address) }
    end

    private

    def trusted_networks
      if ENV['TRUSTED_NETWORKS'].present?
        ENV['TRUSTED_NETWORKS']
          .split
          .map { |string| parse_address(string) }
          .compact
      else
        []
      end
    end

    def parse_address(address)
      begin
        IPAddr.new(address)
      rescue
        nil
      end
    end
  end
end
