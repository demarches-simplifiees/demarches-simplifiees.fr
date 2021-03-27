RSpec.describe APIEntreprise::EntrepriseJob, type: :job do
  let(:siret) { '41816609600051' }
  let(:siren) { '418166096' }
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/entreprises.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/entreprises\/#{siren}/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { APIEntreprise::EntrepriseJob.new.perform(etablissement.id, procedure_id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_numero_tva_intracommunautaire).to eq('FR16418166096')
  end
end
