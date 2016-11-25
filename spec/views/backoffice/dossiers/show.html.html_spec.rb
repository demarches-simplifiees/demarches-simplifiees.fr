require 'spec_helper'

describe 'backoffice/dossiers/show.html.haml', type: :view do
  let!(:dossier) { create(:dossier, :with_entreprise,  state: state) }
  let(:state) { 'draft' }
  let(:dossier_id) { dossier.id }
  let(:gestionnaire) { create(:gestionnaire) }

  before do
    sign_in gestionnaire
    assign(:facade, (DossierFacades.new dossier.id, gestionnaire.email))

    @request.env['PATH_INFO'] = 'backoffice/user'
  end

  context 'on the dossier gestionnaire page' do
    before do
      render
    end

    it 'button Modifier les document est present' do
      expect(rendered).not_to have_content('Modifier les documents')
      expect(rendered).not_to have_css('#UploadPJmodal')
    end

    it 'enterprise informations are present' do
      expect(rendered).to have_selector('#infos_entreprise')
    end

    it 'dossier informations are present' do
      expect(rendered).to have_selector('#infos_dossier')
    end

    it 'dossier number is present' do
      expect(rendered).to have_selector('#dossier_id')
      expect(rendered).to have_content(dossier_id)
    end

    context 'edit link are present' do
      it 'edit carto' do
        expect(rendered).to_not have_selector('a[id=modif_carte]')
      end

      it 'edit description' do
        expect(rendered).to_not have_selector('a[id=modif_description]')
      end

      it 'Editer mon dossier button doesnt present' do
        expect(rendered).to_not have_css('#maj_infos')
      end
    end
  end

  context 'dossier state changements' do
    context 'when dossier have state initiated' do
      let(:state) { 'initiated' }

      before do
        render
      end

      it { expect(rendered).to have_content('Nouveau') }

      it 'button Déclarer complet is present' do
        expect(rendered).to have_css('.action_button')
        expect(rendered).to have_content('Déclarer complet')
      end
    end

    context 'when dossier have state replied' do
      let(:state) { 'replied' }

      before do
        render
      end

      it { expect(rendered).to have_content('Répondu') }

      it 'button Déclarer complet is present' do
        expect(rendered).to have_css('.action_button')
        expect(rendered).to have_content('Déclarer complet')
      end
    end

    context 'when dossier have state update' do
      let(:state) { 'updated' }

      before do
        render
      end

      it { expect(rendered).to have_content('Mis à jour') }

      it 'button Déclarer complet is present' do
        expect(rendered).to have_css('.action_button')
        expect(rendered).to have_content('Déclarer complet')
      end
    end

    context 'when dossier have state validated' do
      let(:state) { 'validated' }

      before do
        render
      end

      it { expect(rendered).to have_content('Figé') }

      it 'button Déclarer complet  is not present' do
        expect(rendered).not_to have_css('.action_button')
        expect(rendered).not_to have_content('Déclarer complet')
      end
    end

    context 'when dossier have state submitted' do
      let(:state) { 'submitted' }

      before do
        render
      end

      it { expect(rendered).to have_content('Déposé') }

      it 'button Accuser réception is present' do
        expect(rendered).to have_css('.action_button')
        expect(rendered).to have_content('Accuser réception')
      end

      it 'button Déclarer complet is not present' do
        expect(rendered).not_to have_content('Accepter le dossier')
      end
    end

    context 'when dossier have state received' do
      let(:state) { 'received' }

      before do
        render
      end

      it { expect(rendered).to have_content('Reçu') }

      it 'button accepter / refuser / classer sans suite are present' do
        expect(rendered).to have_css('.action_button[data-toggle="tooltip"][title="Accepter"]')
        expect(rendered).to have_css('.action_button[data-toggle="tooltip"][title="Classer sans suite"]')
        expect(rendered).to have_css('.action_button[data-toggle="tooltip"][title="Refuser"]')
      end
    end

    context 'when dossier have state closed' do
      let(:state) { 'closed' }

      before do
        render
      end

      it { expect(rendered).to have_content('Accepté') }

      it 'button Accepter le dossier is not present' do
        expect(rendered).not_to have_css('.action_button[data-toggle="tooltip"][title="Accepter"]')
        expect(rendered).not_to have_css('.action_button[data-toggle="tooltip"][title="Classer sans suite"]')
        expect(rendered).not_to have_css('.action_button[data-toggle="tooltip"][title="Refuser"]')
      end
    end

    context 'when dossier have state without_continuation' do
      let(:state) { 'without_continuation' }

      before do
        render
      end

      it { expect(rendered).to have_content('Sans suite') }

      it 'button Déclarer complet is not present' do
        expect(rendered).not_to have_css('.action_button[data-toggle="tooltip"][title="Accepter"]')
        expect(rendered).not_to have_css('.action_button[data-toggle="tooltip"][title="Classer sans suite"]')
        expect(rendered).not_to have_css('.action_button[data-toggle="tooltip"][title="Refuser"]')
      end
    end

    context 'when dossier have state refused' do
      let(:state) { 'refused' }

      before do
        render
      end

      it { expect(rendered).to have_content('Refusé') }

      it 'button Déclarer complet is not present' do
        expect(rendered).not_to have_css('.action_button[data-toggle="tooltip"][title="Accepter"]')
        expect(rendered).not_to have_css('.action_button[data-toggle="tooltip"][title="Classer sans suite"]')
        expect(rendered).not_to have_css('.action_button[data-toggle="tooltip"][title="Refuser"]')
      end
    end
  end

  #TODO réactiver
  # context 'la liste des pièces justificatives est présente' do
  #   context 'Attestation MSA' do
  #     let(:id_piece_justificative) { 93 }
  #
  #     it 'la ligne de la pièce justificative est présente' do
  #       expect(rendered).to have_selector("tr[id=piece_justificative_#{id_piece_justificative}]")
  #     end
  #
  #     it 'le bouton "Récupérer" est présent' do
  #       expect(rendered.find("tr[id=piece_justificative_#{id_piece_justificative}]")).to have_selector("a[href='']")
  #       expect(rendered.find("tr[id=piece_justificative_#{id_piece_justificative}]")).to have_content('Récupérer')
  #     end
  #   end
  #
  #   context 'Attestation RDI' do
  #     let(:id_piece_justificative) { 103 }
  #
  #     it 'la ligne de la pièce justificative est présente' do
  #       expect(rendered).to have_selector("tr[id=piece_justificative_#{id_piece_justificative}]")
  #     end
  #
  #     it 'le libelle "Pièce manquante" est présent' do
  #       expect(rendered.find("tr[id=piece_justificative_#{id_piece_justificative}]")).to have_content('Pièce non fournie')
  #     end
  #   end
  #
  #   context 'Devis' do
  #     let(:id_piece_justificative) { 388 }
  #     let(:content) { File.open('./spec/support/files/piece_justificative_388.pdf') }
  #
  #     before do
  #       piece_justificative = dossier.pieces_justificatives.where(type_de_piece_justificative_id: 388).first
  #       piece_justificative.content = content
  #       piece_justificative.save!
  #       visit "/admin/dossiers/#{dossier_id}"
  #     end
  #
  #     it 'la ligne de la pièce justificative est présente' do
  #       expect(rendered).to have_selector("tr[id=piece_justificative_#{id_piece_justificative}]")
  #     end
  #
  #     it 'le libelle "Consulter" est présent' do
  #       expect(rendered.find("tr[id=piece_justificative_#{id_piece_justificative}] a")[:href]).to have_content('piece_justificative_388.pdf')
  #       expect(rendered.find("tr[id=piece_justificative_#{id_piece_justificative}]")).to have_content('Consulter')
  #     end
  #   end
  # end
  #
end
