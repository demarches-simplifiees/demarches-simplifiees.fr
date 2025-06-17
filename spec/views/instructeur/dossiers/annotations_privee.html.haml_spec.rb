# frozen_string_literal: true

describe 'instructeurs/dossiers/annotations_privees', type: :view do
  let(:current_instructeur) { create(:instructeur) }
  let(:dossier) { create(:dossier, :en_construction) }
  let(:procedure_presentation) { double(instructeur: current_instructeur, procedure: dossier.procedure) }
  let(:notifications) { [] }
  let(:notifications_sticker) { { demande: false, annotations_instructeur: false, avis_externe: false, messagerie: false } }

  before do
    sign_in(current_instructeur.user)
    allow(view).to receive(:current_instructeur).and_return(current_instructeur)

    allow(controller).to receive(:params).and_return({ statut: 'a-suivre' })
    assign(:dossier, dossier)
    assign(:procedure_presentation, procedure_presentation)
    assign(:notifications, notifications)
    assign(:notifications_sticker, notifications_sticker)
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
