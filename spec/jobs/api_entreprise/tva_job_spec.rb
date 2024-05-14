# frozen_string_literal: true

describe APIEntreprise::TvaJob, type: :job do
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/tva.json') }
  let(:status) { 200 }
  subject { APIEntreprise::TvaJob.new.perform(etablissement.id, procedure_id) }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/european_commission\/unites_legales\/#{siren}\/numero_tva/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_numero_tva_intracommunautaire).to eq("FR48672039971")
  end
end
