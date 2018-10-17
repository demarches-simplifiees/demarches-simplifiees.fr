describe 'shared/dossiers/identite_entreprise.html.haml', type: :view do
  before { render 'shared/dossiers/identite_entreprise.html.haml', etablissement: etablissement, profile: 'usager' }

  context "there is an association" do
    let(:etablissement) { create(:etablissement, :is_association) }

    context "date_publication is missing on rna" do
      before { etablissement.update(association_date_publication: nil) }

      it "can render without error" do
        expect(rendered).to include("Date de publication :")
      end
    end
  end
end
