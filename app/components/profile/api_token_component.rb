class Profile::APITokenComponent < ApplicationComponent
  def initialize(api_token:, packed_token: nil)
    @api_token = api_token
    @packed_token = packed_token
  end
end
