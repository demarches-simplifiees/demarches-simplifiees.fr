# frozen_string_literal: true

describe APIEntreprise::ExtraitKbisJob, type: :job do
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:siret) { '13002526500013' }
  let(:siren) { '130025265' }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/extrait_kbis.json') }
  let(:status) { 200 }
  subject { APIEntreprise::ExtraitKbisJob.new.perform(etablissement.id, procedure_id) }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/infogreffe\/rcs\/unites_legales\/#{siren}\/extrait_kbis/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_capital_social).to eq(50123)
    expect(Etablissement.find(etablissement.id).entreprise_nom_commercial).to eq('DECATHLON')
  end
end
