# frozen_string_literal: true

describe 'instructeurs/dossiers/print', type: :view do
  before { view.extend DossierHelper }

  context "with a dossier" do
    let(:current_instructeur) { create(:instructeur) }
    let(:dossier) { create(:dossier, :en_instruction, :with_commentaires) }

    before do
      assign(:dossier, dossier)
      allow(view).to receive(:current_instructeur).and_return(current_instructeur)

      render
    end

    it do
      expect(rendered).to include("Dossier n° #{dossier.id}")
      expect(rendered).to include(dossier.procedure.libelle)
    end
  end
end
