RSpec.describe ApiEntreprise::BilansBdfJob, type: :job do
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:procedure) { etablissement.dossier.procedure }
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/bilans_entreprise_bdf.json') }
  let(:status) { 200 }
  let(:bilans_bdf) { JSON.parse(body)["bilans"] }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/bilans_entreprises_bdf\/#{siren}\?.*token=/)
      .to_return(body: body, status: status)
    allow_any_instance_of(ApiEntrepriseToken).to receive(:roles).and_return(["bilans_entreprise_bdf"])
    allow_any_instance_of(ApiEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { ApiEntreprise::BilansBdfJob.new.perform(etablissement.id, procedure.id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_bilans_bdf).to eq(bilans_bdf)
  end
end
