# frozen_string_literal: true

RSpec.describe APIEntreprise::EffectifsAnnuelsJob, type: :job do
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:now) { Date.parse("2021/02/13") }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/effectifs_annuels.json') }
  let(:status) { 200 }

  before do
    travel_to(now)
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/gip_mds\/unites_legales\/#{siren}\/effectifs_annuels\/2020/)
      .to_return(body: body, status: status)
  end

  subject { APIEntreprise::EffectifsAnnuelsJob.new.perform(etablissement.id, procedure_id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_effectif_annuel).to eq(100.5)
    expect(Etablissement.find(etablissement.id).entreprise_effectif_annuel_annee).to eq("2017")
  end
end
