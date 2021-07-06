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

    before { cookies.update(request_cookies) }

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

      it 'returns a message' do
        post :invalid_authenticity_token

        expect(response).to have_http_status(403)
        expect(response.body).to include('cookies')
      end

      it 'renders the standard exception page' do
        expect { post :invalid_authenticity_token }.not_to raise_error
      end
    end
  end
end
