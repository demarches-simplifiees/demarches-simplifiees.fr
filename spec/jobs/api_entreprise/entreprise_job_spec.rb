# frozen_string_literal: true

RSpec.describe APIEntreprise::EntrepriseJob, type: :job do
  let(:siret) { '41816609600051' }
  let(:siren) { '418166096' }
  let(:etablissement) { create(:etablissement, siret: siret, entreprise_etat_administratif: nil) }
  let(:procedure) { create(:procedure) }
  let(:procedure_id) { procedure.id }
  let(:body) { File.read('spec/fixtures/files/api_entreprise/entreprises.json') }
  let(:status) { 200 }

  before do
    stub_request(:get, /https:\/\/entreprise.api.gouv.fr\/v3\/insee\/sirene\/unites_legales\/#{siren}/)
      .to_return(body: body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)
  end

  subject { APIEntreprise::EntrepriseJob.new.perform(etablissement.id, procedure_id) }

  it 'updates etablissement' do
    subject
    expect(Etablissement.find(etablissement.id).entreprise_raison_sociale).to eq("DIRECTION INTERMINISTERIELLE DU NUMERIQUE")
  end

  it 'convert entreprise etat_administratif source to an enum' do
    subject
    etablissement.reload

    expect(etablissement.entreprise_etat_administratif).to eq("actif")
    expect(etablissement.entreprise_etat_administratif_actif?)
  end
end
