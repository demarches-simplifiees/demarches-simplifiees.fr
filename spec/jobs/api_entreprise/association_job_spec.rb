RSpec.describe ApiEntreprise::AssociationJob, type: :job do
  let(:siret) { '50480511000013' }
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:procedure) { etablissement.dossier.procedure }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/associations.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/associations\/.*token=/)
      .to_return(body: body, status: status)
    allow_any_instance_of(ApiEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { ApiEntreprise::AssociationJob.new.perform(etablissement.id, procedure.id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).association_rna).to eq('W595001988')
  end
end
