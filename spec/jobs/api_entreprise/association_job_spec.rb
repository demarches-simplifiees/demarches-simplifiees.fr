# frozen_string_literal: true

RSpec.describe APIEntreprise::AssociationJob, type: :job do
  let(:siret) { '50480511000013' }
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/djepva\/api-association\/associations\/open_data\/#{siret}/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { APIEntreprise::AssociationJob.new.perform(etablissement.id, procedure_id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).association_rna).to eq("W751080001")
  end

  context "when the etablissement has been deleted" do
    before do
      allow_any_instance_of(Etablissement).to receive(:find) { raise ActiveRecord::RecordNotFound }
    end

    it "ignores the error" do
      expect { subject }.not_to raise_error
    end
  end
end
