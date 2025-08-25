# frozen_string_literal: true

require 'rails_helper'

describe DataSources::ReferentielController, type: :controller do
  include Dry::Monads[:result]
  describe 'GET #search' do
    let(:procedure) { create(:procedure, types_de_champ_public:) }
    let(:types_de_champ_public) { [{ type: :referentiel, referentiel: }] }
    let(:referentiel) { create(:api_referentiel, :autocomplete, :with_autocomplete_response) }
    before do
      allow(ReferentielService).to receive(:new).with(referentiel).and_return(referentiel_service)
    end

    context 'with valid params' do
      let(:body) { { 'result' => 'ok' } }
      let(:referentiel_service) { double(call: Success(body)) }

      it 'returns formatted results' do
        get :search, params: { q: 'noop', referentiel_id: '1' }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
      end
    end

    context 'when service fails' do
      let(:referentiel_service) { double(call: Failure(code: 404)) }

      it 'returns an empty array and logs the error' do
        get :search, params: { q: 'abc', referentiel_id: '1' }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
      end
    end
  end
end
