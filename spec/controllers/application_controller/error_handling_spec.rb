# frozen_string_literal: true

RSpec.describe ApplicationController::ErrorHandling, type: :controller do
  controller(ActionController::Base) do
    include ApplicationController::ErrorHandling

    def invalid_authenticity_token
      raise ActionController::InvalidAuthenticityToken
    end
  end

  before do
    routes.draw { post 'invalid_authenticity_token' => 'anonymous#invalid_authenticity_token' }
  end

  describe 'handling ActionController::InvalidAuthenticityToken' do
    let(:request_cookies) do
      { 'some_cookie': true }
    end

    before do
      cookies.update(request_cookies)
      allow(controller).to receive(:rand).and_return(0)
    end

    it 'returns a 403 forbidden status' do
      post :invalid_authenticity_token
      expect(response).to have_http_status(:forbidden)
    end
  end
end
