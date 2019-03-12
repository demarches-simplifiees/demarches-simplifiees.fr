require 'spec_helper'

describe APIController, type: :controller do
  describe 'valid_token_for_procedure?' do
    let(:procedure) { create(:procedure) }
    let(:admin) { procedure.administrateurs.first }

    subject { controller.send(:'valid_token_for_procedure?', procedure) }

    context 'when the admin has not any token' do
      context 'and the token is not given' do
        it { is_expected.to be false }
      end
    end

    context 'when the admin has a token' do
      let!(:token) { admin.renew_api_token }

      context 'and the token is given by params' do
        before { controller.params[:token] = token }

        it { is_expected.to be true }
      end

      context 'and the token is given by header' do
        before do
          valid_headers = { 'Authorization' => "Bearer token=#{token}" }
          request.headers.merge!(valid_headers)
        end

        it { is_expected.to be true }
      end

      context 'and the token is not given' do
        it { is_expected.to be false }
      end
    end
  end
end
