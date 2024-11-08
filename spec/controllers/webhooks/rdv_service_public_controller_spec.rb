# frozen_string_literal: true

describe Webhooks::RdvServicePublicController, type: :controller do
  describe 'POST #create' do
    let(:dossier) { create(:dossier) }
    let(:rdv) { create(:rdv, rdv_service_public_id: '123', dossier: dossier, status: 'unknown') }
    let(:webhook_payload) do
      {
        data: {
          id: rdv.rdv_service_public_id,
          title: "RDV with John Doe",
          starts_at: "2024-03-21T14:00:00Z",
          status: "seen"
        },
        meta: {
          model: "Rdv",
          event: "updated",
          webhook_reason: "status_change",
          timestamp: "2024-03-21T10:00:00Z"
        }
      }
    end

    it 'returns a successful response' do
      post :create, params: webhook_payload
      expect(response).to have_http_status(:success)
    end

    it 'returns the expected JSON response' do
      post :create, params: webhook_payload
      expect(response.parsed_body).to eq({ 'message' => 'OK' })
    end

    it 'updates the rdv status' do
      expect {
        post :create, params: webhook_payload, as: :json
      }.to change { rdv.reload.status }.from('unknown').to('seen')
    end
  end
end
