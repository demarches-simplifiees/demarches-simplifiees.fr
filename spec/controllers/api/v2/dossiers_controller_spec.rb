# frozen_string_literal: true

describe API::V2::DossiersController do
  let(:dossier) { create(:dossier, :accepte, :with_attestation_acceptation) }
  let(:sgid) { dossier.to_sgid(expires_in: 1.hour, for: 'api_v2') }

  describe 'fetch pdf' do
    subject { get :pdf, params: { id: sgid } }

    it 'should get' do
      expect(subject.status).to eq(200)
      expect(subject.body).not_to be_nil
    end

    context 'error' do
      let(:sgid) { 'yolo' }

      it 'should error' do
        expect(subject.status).to eq(401)
      end
    end
  end

  describe 'fetch geojson' do
    subject { get :geojson, params: { id: sgid } }

    it 'should get' do
      expect(subject.status).to eq(200)
      expect(subject.body).not_to be_nil
    end

    context 'error' do
      let(:sgid) { 'yolo' }

      it 'should error' do
        expect(subject.status).to eq(401)
      end
    end
  end
end
