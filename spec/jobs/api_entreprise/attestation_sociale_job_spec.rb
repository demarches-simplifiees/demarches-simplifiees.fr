# frozen_string_literal: true

include ActiveJob::TestHelper

RSpec.describe APIEntreprise::AttestationSocialeJob, type: :job do
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure) }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/attestation_sociale.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v4\/urssaf\/unites_legales\/#{siren}\/attestation_vigilance/)
      .to_return(body: body, status: status)
    stub_request(:get, "https://storage.entreprise.api.gouv.fr/siade/1569139162-b99824d9c764aae19a862a0af-attestation_vigilance_acoss.pdf")
      .to_return(body: "body attestation", status: 200)
    allow_any_instance_of(APIEntrepriseToken).to receive(:can_fetch_attestation_sociale?).and_return(true)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { APIEntreprise::AttestationSocialeJob.new.perform(etablissement.id, procedure.id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_attestation_sociale).to be_attached
  end
end
