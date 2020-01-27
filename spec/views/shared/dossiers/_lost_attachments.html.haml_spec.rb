describe 'shared/dossiers/lost_attachments.html.haml', type: :view do
  let(:procedure) { create(:procedure, :published) }
  let(:dossier) { create(:dossier, :en_construction, procedure: procedure) }

  subject { render 'shared/dossiers/lost_attachments.html.haml', dossier: dossier, profile: profile }

  context 'when viewed by an Usager' do
    let(:profile) { 'usager' }

    it 'displays a warning message' do
      expect(subject).to include('Des pièces jointes de votre dossier peuvent être manquantes')
      expect(subject).to have_link('renvoyer les pièces jointes manquantes', href: modifier_dossier_path(dossier))
    end

    context 'when the user can’t edit the dossier' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }

      it 'suggest to wait' do
        expect(subject).to include('l’administration vous contactera')
      end
    end
  end

  context 'when viewed by an Instructeur' do
    let(:profile) { 'instructeur' }

    it 'displays a warning message' do
      expect(subject).to include('Des pièces jointes de ce dossier peuvent être manquantes')
      expect(subject).to have_link('contacter le demandeur')
    end

    context 'when the user can’t edit the dossier' do
      let(:dossier) { create(:dossier, :en_instruction, procedure: procedure) }

      it 'suggest to make the dossier editable again' do
        expect(subject).to include('repasser ce dossier en construction')
      end
    end
  end
end
