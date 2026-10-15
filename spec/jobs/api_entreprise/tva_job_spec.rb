# frozen_string_literal: true

describe APIEntreprise::TvaJob, type: :job do
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:procedure) { create(:procedure, api_entreprise_token: JWT.encode({ exp: 2.months.from_now.to_i }, nil, 'none')) }
  let(:procedure_id) { procedure.id }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/tva.json') }
  let(:status) { 200 }
  subject { described_class.perform_now(etablissement.id, procedure_id) }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/dgfip\/unites_legales\/#{siren}\/numero_tva/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_numero_tva_intracommunautaire).to eq("FR48672039971")
  end

  context 'when the provider fails' do
    let(:status) { 503 }

    it 'waits in the table for the cron' do
      expect { subject }.not_to raise_error
      expect(ParkedAPIEntrepriseFetch.find_by(etablissement:, job: 'TvaJob'))
        .to have_attributes(procedure_id: procedure.id, code: 503)
    end
  end
end
