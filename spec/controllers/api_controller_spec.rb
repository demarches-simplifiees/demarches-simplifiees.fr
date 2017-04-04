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
    context 'when token is missing' do
      subject { get :index }
      it { expect(subject.status).to eq(401) }
    end
    context 'when token does not exist' do
      let(:token) { 'invalid_token' }
      subject { get :index, params: {token: token} }
      it { expect(subject.status).to eq(401) }
    end
    context 'when token exist' do
      let(:administrateur) { create(:administrateur) }
      subject { get :index, params: {token: administrateur.api_token} }
      it { expect(subject.status).to eq(200) }
    end
  end
end
