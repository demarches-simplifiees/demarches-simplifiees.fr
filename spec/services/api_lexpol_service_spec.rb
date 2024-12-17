require 'rails_helper'

RSpec.describe APILexpol do
  let(:api_lexpol) { described_class.new }

  before do
    allow(ENV).to receive(:fetch).with('API_LEXPOL_EMAIL').and_return('fake_email@example.com')
    allow(ENV).to receive(:fetch).with('API_LEXPOL_PASSWORD').and_return('fake_password')
    allow(ENV).to receive(:fetch).with('API_LEXPOL_AGENT_EMAIL').and_return('fake_agent_email@example.com')
  end

  describe '#authenticate' do
    it 'retrieves a token from the API' do
      VCR.use_cassette('authenticate') do
        token = api_lexpol.authenticate
        expect(token).not_to be_nil
      end
    end
  end

  describe '#get_models' do
    it 'retrieves the list of models' do
      VCR.use_cassette('get_models') do
        models = api_lexpol.get_models
        expect(models['modeles']).to be_an(Array)
      end
    end
  end

  describe '#create_dossier' do
    let(:modele_id) { 598706 }
    let(:variables) { { 'nom' => 'Test', 'description' => 'Test dossier' } }

    it 'creates a dossier and returns the NOR' do
      VCR.use_cassette('create_dossier') do
        nor = api_lexpol.create_dossier(modele_id, variables)
        expect(nor).to eq('ZZZ24000882TT')
      end
    end
  end

  describe '#update_dossier' do
    let(:nor) { 'ZZZ24000882TT' }
    let(:variables) { { 'nom' => 'Updated Test' } }

    it 'updates a dossier successfully' do
      VCR.use_cassette('update_dossier') do
        result = api_lexpol.update_dossier(nor, variables)
        expect(result).to eq(nor)
      end
    end
  end
end
