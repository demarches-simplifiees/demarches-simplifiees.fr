RSpec.describe ApiEntreprise::EffectifsAnnuelsJob, type: :job do
  let(:etablissement) { create(:etablissement, siret: siret) }
  let(:procedure) { etablissement.dossier.procedure }
  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/effectifs_annuels.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v2\/effectifs_annuels_acoss_covid\/#{siren}\?.*token=/)
      .to_return(body: body, status: status)
    allow_any_instance_of(ApiEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { ApiEntreprise::EffectifsAnnuelsJob.new.perform(etablissement.id, procedure.id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_effectif_annuel).to eq(100.5)
  end
end
