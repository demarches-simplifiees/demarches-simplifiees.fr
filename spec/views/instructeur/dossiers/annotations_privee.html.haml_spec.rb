describe 'instructeurs/dossiers/annotations_privees', type: :view do
  let(:current_instructeur) { create(:instructeur) }
  let(:dossier) { create(:dossier, :en_construction) }

  before do
    sign_in(current_instructeur.user)
    allow(view).to receive(:current_instructeur).and_return(current_instructeur)
    assign(:dossier, dossier)
  end

  subject { render }

  describe 'when header_sections are present' do
    let(:procedure) { create(:procedure, types_de_champ_private:) }
    let(:types_de_champ_private) do
      [
        { type: :header_section, level: 1, libelle: 'l1' }
      ]
    end
    let(:dossier) { create(:dossier, :en_construction, procedure:) }

    it 'displays a link to header_section' do
      expect(subject).to have_selector('a.fr-sidemenu__link', text: 'l1')
    end
  end
end
