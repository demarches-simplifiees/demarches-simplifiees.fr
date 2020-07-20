RSpec.describe ApiEntreprise::AttestationSocialeJob, type: :job do
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:procedure) { etablissement.dossier.procedure }
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/attestation_sociale.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/attestations_sociales_acoss\/#{siren}\?.*token=/)
      .to_return(body: body, status: status)
    stub_request(:get, "https://storage.entreprise.api.gouv.fr/siade/1569156881-f749d75e2bfd443316e2e02d59015f-attestation_vigilance_acoss.pdf")
      .to_return(body: "body attestation", status: 200)
    allow_any_instance_of(ApiEntrepriseToken).to receive(:roles).and_return(["attestations_sociales"])
    allow_any_instance_of(ApiEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { ApiEntreprise::AttestationSocialeJob.new.perform(etablissement.id, procedure.id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_attestation_sociale).to be_attached
  end
end
