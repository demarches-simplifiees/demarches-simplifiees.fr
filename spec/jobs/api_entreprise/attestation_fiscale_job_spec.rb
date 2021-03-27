RSpec.describe APIEntreprise::AttestationFiscaleJob, type: :job do
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure) }
  let(:user_id) { 1 }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/attestation_fiscale.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/attestations_fiscales_dgfip\/#{siren}/)
      .to_return(body: body, status: status)
    stub_request(:get, "https://storage.entreprise.api.gouv.fr/siade/1569156756-f6b7779f99fa95cd60dc03c04fcb-attestation_fiscale_dgfip.pdf")
      .to_return(body: "body attestation", status: 200)
    allow_any_instance_of(APIEntrepriseToken).to receive(:roles).and_return(["attestations_fiscales"])
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { APIEntreprise::AttestationFiscaleJob.new.perform(etablissement.id, procedure.id, user_id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_attestation_fiscale).to be_attached
  end
end
