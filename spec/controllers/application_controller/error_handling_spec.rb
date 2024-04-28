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

    it 'logs the error' do
      allow(Sentry).to receive(:capture_message)
      post :invalid_authenticity_token rescue nil
      expect(Sentry).to have_received(:capture_message)
    end

    it 'forwards the error upwards' do
      expect { post :invalid_authenticity_token }.to raise_error(ActionController::InvalidAuthenticityToken)
    end

    context 'when Safari retries a POST request without cookies' do
      let(:request_cookies) do
        {}
      end

      it 'doesn’t log the error' do
        allow(Sentry).to receive(:capture_message)
        post :invalid_authenticity_token rescue nil
        expect(Sentry).not_to have_received(:capture_message)
      end
    end
  end
end
