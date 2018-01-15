class FranceConnectSaltService
  attr_reader :model

  def initialize france_connect_information
    raise 'Not a FranceConnectInformation class' if france_connect_information.class != FranceConnectInformation
    @model = france_connect_information
  end

  def valid? test_salt
    salt == test_salt
  end

  def salt
    Digest::MD5.hexdigest(model.france_connect_particulier_id + model.given_name + model.family_name + FRANCE_CONNECT[:particulier][:secret] + DateTime.now.to_date.to_s)
  end
end
