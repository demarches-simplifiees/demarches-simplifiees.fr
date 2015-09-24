require 'spec_helper'

describe 'backoffice/dossiers/show.html.haml', type: :view do
  let!(:dossier) { create(:dossier, :with_entreprise, :with_procedure, :with_user) }
  let(:dossier_id) { dossier.id }

  before do
    sign_in create(:gestionnaire)

    assign(:dossier, dossier.decorate)
    assign(:entreprise, dossier.entreprise.decorate)
    assign(:etablissement, dossier.etablissement)
    assign(:procedure, dossier.procedure)
    assign(:commentaires, dossier.commentaires)
  end

  context 'sur la rendered admin du dossier' do
    before do
      render
    end
    it 'la section infos entreprise est présente' do
      expect(rendered).to have_selector('#infos_entreprise')
    end

    it 'la section infos dossier est présente' do
      expect(rendered).to have_selector('#infos_dossier')
    end

    it 'le numéro de dossier est présent sur la rendered' do
      expect(rendered).to have_selector('#dossier_id')
      expect(rendered).to have_content(dossier_id)
    end

    context 'les liens de modifications sont non présent' do
      it 'le lien vers carte' do
        expect(rendered).to_not have_selector('a[id=modif_carte]')
      end

      it 'le lien vers description' do
        expect(rendered).to_not have_selector('a[id=modif_description]')
      end

      it 'le bouton Editer mon dossier n\'est pas present' do
        expect(rendered).to_not have_css('#maj_infos')
      end
    end
  end

  context 'gestion des etats du dossier' do
    context 'when dossier have state proposed' do
      before do
        dossier.proposed!
        render
      end

      it { expect(rendered).to have_content('Soumis') }

      it 'button Valider le dossier est present' do
        expect(rendered).to have_css('#action_button')
        expect(rendered).to have_content('Valider le dossier')
      end
    end

    context 'when dossier have state reply' do
      before do
        dossier.reply!
        render
      end

      it { expect(rendered).to have_content('Répondu') }

      it 'button Valider le dossier est present' do
        expect(rendered).to have_css('#action_button')
        expect(rendered).to have_content('Valider le dossier')
      end
    end

    context 'when dossier have state update' do
      before do
        dossier.updated!
        render
      end

      it { expect(rendered).to have_content('Mis à jour') }

      it 'button Valider le dossier est present' do
        expect(rendered).to have_css('#action_button')
        expect(rendered).to have_content('Valider le dossier')
      end
    end

    context 'when dossier have state confirmed' do
      before do
        dossier.confirmed!
        render
      end

      it { expect(rendered).to have_content('Validé') }

      it 'button Valider le dossier n\'est pas present' do
        expect(rendered).not_to have_css('#action_button')
        expect(rendered).not_to have_content('Valider le dossier')
      end
    end

    context 'when dossier have state deposited' do
      before do
        dossier.deposited!
        render
      end

      it { expect(rendered).to have_content('Déposé') }

      it 'button Valider le dossier n\'est pas present' do
        expect(rendered).not_to have_css('#action_button')
        expect(rendered).not_to have_content('Valider le dossier')
      end
    end

    context 'when dossier have state processed' do
      before do
        dossier.processed!
        render
      end

      it { expect(rendered).to have_content('Traité') }

      it 'button Valider le dossier n\'est pas present' do
        expect(rendered).not_to have_css('#action_button')
        expect(rendered).not_to have_content('Valider le dossier')
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
