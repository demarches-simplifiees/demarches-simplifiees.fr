class Profile::APITokenCardComponent < ApplicationComponent
  def initialize(created_api_token: nil, created_packed_token: nil)
    @created_api_token = created_api_token
    @created_packed_token = created_packed_token
  end

  private

  def render?
    current_administrateur.present?
  end

  def api_and_packed_tokens
    current_administrateur.api_tokens.order(:created_at).map do |api_token|
      if api_token == @created_api_token && @created_packed_token.present?
        [api_token, @created_packed_token]
      else
        [api_token, nil]
      end
    end
  end
end
