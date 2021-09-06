describe APIParticulier::API do
  let(:token) { "d7e9c9f4c3ca00caadde31f50fd4521a" }
  let(:api) { APIParticulier::API.new(token) }

  describe "introspect" do
    subject { api.introspect }

    it "doit retourner une introspection valide" do
      VCR.use_cassette("api_particulier/success/introspect") do
        expect(subject.id).to be_nil
        expect(subject.name).to eql("Application de sandbox")
        expect(subject.email).to be_nil
        expect(subject.scopes).to be_instance_of(Array)
        expect(subject.scopes).to match_array(['dgfip_avis_imposition', 'dgfip_adresse', 'cnaf_allocataires', 'cnaf_enfants', 'cnaf_adresse', 'cnaf_quotient_familial', 'mesri_statut_etudiant'])
      end
    end
  end
end
