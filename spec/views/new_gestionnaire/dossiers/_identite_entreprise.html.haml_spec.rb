describe 'new_gestionnaire/dossiers/identite_entreprise.html.haml', type: :view do
  helper(EntrepriseHelper)

  before { render 'new_gestionnaire/dossiers/identite_entreprise.html.haml', entreprise: entreprise }

  context "there is an association" do
    let(:rna_information) { create(:rna_information) }
    let(:entreprise) { rna_information.entreprise }

    context "date_publication is missing on rna" do
      before { rna_information.update_attributes(date_publication: nil) }

      it "can render without error" do
        expect(rendered).to include("Date de publication :")
      end
    end
  end
end
