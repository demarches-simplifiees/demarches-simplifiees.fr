require 'spec_helper'

describe APIController, type: :controller do
  controller(APIController) do
    def show
      render json: {}, satus: 200
    end

    def index
      render json: {}, satus: 200
    end
  end

  describe 'GET index' do
    let!(:administrateur) { create(:administrateur) }
    let!(:administrateur_with_token) { create(:administrateur, :with_api_token) }

    context 'when token is missing' do
      subject { get :index }

      it { expect(subject.status).to eq(401) }
    end

    context 'when token is empty' do
      subject { get :index, params: { token: nil } }

      it { expect(subject.status).to eq(401) }
    end

    context 'when token does not exist' do
      let(:token) { 'invalid_token' }

      subject { get :index, params: { token: token } }

      it { expect(subject.status).to eq(401) }
    end

    context 'when token exist in the params' do
      subject { get :index, params: { token: administrateur_with_token.api_token } }

      it { expect(subject.status).to eq(200) }
    end

    context 'when token exist in the header' do
      before do
        valid_headers = { 'Authorization' => "Bearer token=#{administrateur_with_token.api_token}" }
        request.headers.merge!(valid_headers)
      end

      subject { get(:index) }

      it { expect(subject.status).to eq(200) }
    end
  end
end
