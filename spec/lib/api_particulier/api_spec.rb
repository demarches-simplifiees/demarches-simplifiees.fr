describe APIParticulier::API do
  let(:token) { "d7e9c9f4c3ca00caadde31f50fd4521a" }
  let(:api) { APIParticulier::API.new(token) }

  before { stub_const("API_PARTICULIER_URL", "https://particulier.api.gouv.fr/api") }

  describe "scopes" do
    subject { api.scopes }

    it "doit retourner une liste de scopes" do
      VCR.use_cassette("api_particulier/success/introspect") do
        expect(subject).to match_array(['dgfip_avis_imposition', 'dgfip_adresse', 'cnaf_allocataires', 'cnaf_enfants', 'cnaf_adresse', 'cnaf_quotient_familial', 'mesri_statut_etudiant'])
      end
    end

    it "returns an unauthorized exception" do
      VCR.use_cassette("api_particulier/unauthorized/introspect") do
        begin
          subject
        rescue APIParticulier::Error::Unauthorized => e
          expect(e.message).to include('url: particulier.api.gouv.fr/api/introspect')
          expect(e.message).to include('HTTP error code: 401')
          expect(e.message).to include("Votre jeton d'API n'a pas été trouvé ou n'est pas actif")
        end
      end
    end
  end
end
