# frozen_string_literal: true

RSpec.describe APIEntreprise::EffectifsJob, type: :job do
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:procedure) { create(:procedure, api_entreprise_token: JWT.encode({ exp: 2.months.from_now.to_i }, nil, 'none')) }
  let(:procedure_id) { procedure.id }
  let(:now) { Time.zone.local(2020, 3, 12) }
  let(:annee) { "2020" }
  let(:mois) { "02" }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/effectifs.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/gip_mds\/etablissements\/#{siret}\/effectifs_mensuels\/#{mois}\/annee\/#{annee}/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  before { travel_to(now) }

  subject { described_class.perform_now(etablissement.id, procedure_id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_effectif_mensuel).to eq(12.34)
  end

  context 'when the provider fails' do
    let(:status) { 503 }

    it 'waits in the table for the cron' do
      expect { subject }.not_to raise_error
      expect(ParkedAPIEntrepriseFetch.find_by(etablissement:, job: 'EffectifsJob'))
        .to have_attributes(procedure_id: procedure.id, code: 503)
    end
  end
end
