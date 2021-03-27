RSpec.describe APIEntreprise::ExercicesJob, type: :job do
  let(:siret) { '41816609600051' }
  let(:procedure) { create(:procedure) }
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/exercices.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/exercices\//)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { APIEntreprise::ExercicesJob.new.perform(etablissement.id, procedure.id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).exercices[0].ca).to eq('21009417')
  end
end
