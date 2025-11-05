# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RdvServicePublic::OauthController, type: :controller do
  describe '#callback' do
    let(:user) { create(:user) }
    let!(:instructeur) { create(:instructeur, user: user) }
    let(:mock_auth_hash) do
      OmniAuth::AuthHash.new({
        credentials: {
          token: 'access_token_123',
          refresh_token: 'refresh_token_456',
          expires_at: 1.hour.from_now.to_i,
        },
      })
    end

    subject { get :callback, params: { provider: 'rdvservicepublic' } }

    before do
      sign_in user
      request.env['omniauth.auth'] = mock_auth_hash
    end

    context 'when user is not signed in' do
      before { sign_out user }

      it 'redirects to sign in path' do
        subject
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when user is signed in' do
      context 'when RDV connection does not exist' do
        it 'creates a new RDV connection' do
          expect {
            subject
          }.to change(RdvConnection, :count).by(1)

          rdv_connection = instructeur.reload.rdv_connection
          expect(rdv_connection.access_token).to eq('access_token_123')
          expect(rdv_connection.refresh_token).to eq('refresh_token_456')
        end
      end

      context 'when RDV connection already exists' do
        let!(:existing_connection) do
          create(:rdv_connection,
                instructeur: instructeur,
                access_token: 'old_token',
                refresh_token: 'old_refresh_token',
                expires_at: 1.day.ago)
        end

        it 'updates the existing RDV connection' do
          expect {
            subject
          }.not_to change(RdvConnection, :count)

          existing_connection.reload
          expect(existing_connection.access_token).to eq('access_token_123')
          expect(existing_connection.refresh_token).to eq('refresh_token_456')
          expect(existing_connection.expires_at).to be_within(1.second).of(Time.zone.at(mock_auth_hash.credentials.expires_at))
        end
      end

      context 'when omniauth.origin is present' do
        before do
          request.env['omniauth.origin'] = '/some/path'
        end

        it 'redirects to the origin path' do
          subject
          expect(response).to redirect_to('/some/path')
          expect(flash[:notice]).to eq('Votre compte RDV Service Public a été connecté avec succès')
        end
      end

      context 'when omniauth.origin is not present' do
        it 'redirects to root path' do
          subject
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to eq('Votre compte RDV Service Public a été connecté avec succès')
        end
      end
    end
  end
end
