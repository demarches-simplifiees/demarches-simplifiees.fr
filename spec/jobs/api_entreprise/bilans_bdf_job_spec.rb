# frozen_string_literal: true

RSpec.describe APIEntreprise::BilansBdfJob, type: :job do
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/bilans_entreprise_bdf.json') }
  let(:status) { 200 }
  let(:bilans_bdf) { JSON.parse(body)["data"] }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/banque_de_france\/unites_legales\/#{siren}\/bilans/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:roles).and_return(["bilans_entreprise_bdf"])
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { APIEntreprise::BilansBdfJob.new.perform(etablissement.id, procedure_id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_bilans_bdf).to eq(bilans_bdf)
  end
end
