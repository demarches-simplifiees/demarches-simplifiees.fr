class FranceConnectService
  def self.retrive_user code
    client = FranceConnectClient.new code: code

    begin
      access_token = client.access_token!(client_auth_method: :secret)
      access_token.userinfo!
    rescue Exception => e
      Rails.logger.error(e.message)
    end
  end
end
