# frozen_string_literal: true

RSpec.describe APIEntreprise::ServiceJob, type: :job do
  let(:siret) { '30613890001294' }
  let(:service) { create(:service, siret: siret) }
  let(:entreprise_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }
  let(:status) { 200 }
  let(:api_entreprise_token) { JWT.encode({ exp: 2.months.from_now.to_i }, nil, 'none') }

  let (:adresse) { "DIRECTION INTERMINISTERIELLE DU NUMERIQUE\r\nJEAN MARIE DURAND\r\nZAE SAINT GUENAULT\r\n51 BIS RUE DE LA PAIX\r\nCS 72809\r\n75256 PARIX CEDEX 12\r\nFRANCE" }

  before do
    stub_request(:get, %r{https://entreprise.api.gouv.fr/v3\/insee\/sirene\/etablissements\/#{siret}})
      .to_return(body: entreprise_body, status: status)

    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('API_ENTREPRISE_KEY').and_return(api_entreprise_token)
  end

  after do
    Geocoder.configure(lookup: :test)
  end

  subject { described_class.new.perform(service.id) }

  it "update service with address, updates departement, geocode" do
    allow(Geocoder).to receive(:search)
      .with(adresse, params: { citycode: "75112", limit: 1 })
      .and_return([double('point', latitude: 48.859, longitude: 2.347)])

    subject
    infos = service.reload.etablissement_infos

    expect(infos).not_to be_empty
    expect(infos["adresse"]).to eq(adresse)
    expect(infos["numero_voie"]).to eq("22")
    expect(infos["code_postal"]).to eq("75016")
    expect(infos["code_insee_localite"]).to eq("75112")
    expect(infos["localite"]).to eq("PARIS 12")

    expect(service.departement).to eq "75"

    expect(service.etablissement_lat).to eq(48.859)
    expect(service.etablissement_lng).to eq(2.347)
  end

  context "errors responses" do
    it "clear attributes when no address match" do
      stub_request(:get, %r{https://entreprise.api.gouv.fr/v3\/insee\/sirene\/etablissements\/#{siret}})
        .to_return(body: "{}", status: 404)
      subject
      service.reload

      expect(service.etablissement_infos).to be_empty
      expect(service.etablissement_lat).to be_nil
      expect(service.etablissement_lng).to be_nil
    end

    it "supports empty geocode result" do
      allow(Geocoder).to receive(:search)
        .with(adresse, params: { citycode: "75112", limit: 1 })
        .and_return([])

      subject
      service.reload

      expect(service.etablissement_lat).to be_nil
      expect(service.etablissement_lng).to be_nil
    end
  end
end
