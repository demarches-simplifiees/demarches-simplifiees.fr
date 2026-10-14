# frozen_string_literal: true

RSpec.describe APIEntreprise::AssociationJob, type: :job do
  let(:siret) { '50480511000013' }
  let(:siren) { siret[0..8] }
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:procedure) { create(:procedure, api_entreprise_token: JWT.encode({ exp: 2.months.from_now.to_i }, nil, 'none')) }
  let(:procedure_id) { procedure.id }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/djepva\/api-association\/associations\/open_data\/#{siren}\?/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { described_class.perform_now(etablissement.id, procedure_id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).association_rna).to eq("W751080001")
  end

  context "when the etablissement already has an address" do
    let(:original_adresse) { "123 rue existante, 75001 Paris" }
    let(:etablissement) { create(:etablissement, siret: siret, adresse: original_adresse) }

    it "does not override the existing address" do
      subject
      expect(Etablissement.find(etablissement.id).adresse).to eq(original_adresse)
    end
  end

  context "when the etablissement has been deleted" do
    before do
      allow_any_instance_of(Etablissement).to receive(:find) { raise ActiveRecord::RecordNotFound }
    end

    it "ignores the error" do
      expect { subject }.not_to raise_error
    end
  end

  context 'when the provider fails' do
    let(:status) { 503 }

    it 'waits in the table for the cron' do
      expect { subject }.not_to raise_error
      expect(ParkedAPIEntrepriseFetch.find_by(etablissement:, job: 'AssociationJob'))
        .to have_attributes(procedure_id: procedure.id, code: 503)
    end
  end
end
