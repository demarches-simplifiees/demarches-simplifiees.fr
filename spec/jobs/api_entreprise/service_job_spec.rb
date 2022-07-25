RSpec.describe APIEntreprise::ServiceJob, type: :job do
  let(:siret) { '41816609600051' }
  let(:service) { create(:service, siret: siret) }
  let(:entreprise_body) { File.read('spec/fixtures/files/api_entreprise/etablissements.json') }
  let(:geocoder_body) { File.read('spec/fixtures/files/api_address/address.json') }
  let(:status) { 200 }

  let (:adresse) { "OCTO TECHNOLOGY\r\n50 AVENUE DES CHAMPS ELYSEES\r\n75008 PARIS\r\nFRANCE" }

  before do
    stub_request(:get, %r{https://entreprise.api.gouv.fr/v2/etablissements/})
      .to_return(body: entreprise_body, status: status)
    allow_any_instance_of(APIEntrepriseToken).to receive(:expired?).and_return(false)

    Geocoder.configure(lookup: :ban_data_gouv_fr, use_https: true)

    stub_request(:get, "https://api-adresse.data.gouv.fr/search/?q=#{adresse}")
      .to_return(body: geocoder_body, status: status)
  end

  after do
    Geocoder.configure(lookup: :test)
  end

  subject { described_class.new.perform(service.id) }

  it "update service with address" do
    subject
    infos = service.reload.etablissement_infos

    expect(infos).not_to be_empty
    expect(infos["adresse"]).to eq(adresse)
    expect(infos["numero_voie"]).to eq("50")
    expect(infos["code_postal"]).to eq("75008")
    expect(infos["localite"]).to eq("PARIS 8")
  end

  it "geocode address" do
    subject
    service.reload

    expect(service.etablissement_lat).to eq(48.859)
    expect(service.etablissement_lng).to eq(2.347)
  end

  context "errors responses" do
    it "clear attributes when no address match" do
      stub_request(:get, %r{https://entreprise.api.gouv.fr/v2/etablissements/})
        .to_return(body: "{}", status: 404)
      subject
      service.reload

      expect(service.etablissement_infos).to be_empty
      expect(service.etablissement_lat).to be_nil
      expect(service.etablissement_lng).to be_nil
    end

    it "supports empty geocode result" do
      geocoder_response = JSON.parse(geocoder_body)
      geocoder_response["features"] = []

      stub_request(:get, "https://api-adresse.data.gouv.fr/search/?q=#{adresse}")
        .to_return(body: JSON.generate(geocoder_response), status: status)

      subject
      service.reload

      expect(service.etablissement_lat).to be_nil
      expect(service.etablissement_lng).to be_nil
    end
  end
end
