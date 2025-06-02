# frozen_string_literal: true

require 'rails_helper'

RSpec.describe APILexpol do
  let(:is_manager) { nil }
  let(:numero_tahiti) { nil }
  let(:api_lexpol) { described_class.new("instructeur@mes-demarches.gov.pf", numero_tahiti, is_manager) }

  before do
    allow(ENV).to receive(:fetch).with('LEXPOL_CERTIFICATE_ENABLED', "").and_return('')
    allow(ENV).to receive(:fetch).with('LEXPOL_EMAIL').and_return('fake_email@example.com')
    allow(ENV).to receive(:fetch).with('LEXPOL_PASSWORD').and_return('fake_password')
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
        expect(models).to be_an(Array)
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

  describe 'determine_email_agent' do
    before do
      allow(APILexpol).to receive(:service_emails).and_return({ '003970' => 'manager@example.com', '004200' => 'admin@other.gov.pf' })
    end

    context "when is_manager = false" do
      let(:is_manager) { false }
      it "keeps the provided email if no TAHITI is given" do
        expect(api_lexpol.instance_variable_get(:@email_agent)).to eq("instructeur@mes-demarches.gov.pf")
      end

      it "keeps the provided email if TAHITI is given" do
        local_api = described_class.new("usager@example.com", "003970", false)
        expect(local_api.instance_variable_get(:@email_agent)).to eq("usager@example.com")
      end
    end

    context "when is_manager = true" do
      let(:is_manager) { true }

      context "and a known TAHITI is provided" do
        let(:numero_tahiti) { "003970" }
        it "uses the corresponding service email" do
          expect(api_lexpol.instance_variable_get(:@email_agent)).to eq("manager@example.com")
        end
      end

      context "and an unknown TAHITI is provided" do
        let(:numero_tahiti) { "999999" }
        it "falls back to the initially given email" do
          expect(api_lexpol.instance_variable_get(:@email_agent)).to eq("instructeur@mes-demarches.gov.pf")
        end
      end
    end
  end
end
