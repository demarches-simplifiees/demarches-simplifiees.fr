require 'spec_helper'

describe DescriptionController, type: :controller do
  let(:dossier) { create(:dossier) }
  let (:dossier_id) { dossier.id }
  let (:bad_dossier_id) { Dossier.count + 10 }

  describe "GET #show" do
    it "returns http success" do
      get :show, :dossier_id => dossier_id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers start si mauvais dossier ID' do
      get :show, :dossier_id => bad_dossier_id
      expect(response).to redirect_to('/start/error_dossier')
    end
  end

  describe "POST #create" do
    let(:timestamp){Time.now}
    let(:nom_projet){'Projet de test'}
    let(:description){'Description de test Coucou, je suis un saut à la ligne Je suis un double saut  la ligne.'}
    let(:montant_projet){12000}
    let(:montant_aide_demande){3000}
    let(:date_previsionnelle){'20/01/2016'}
    let(:mail_contact){'test@test.com'}

    let(:name_piece_jointe){'dossierPDF.pdf'}
    let(:name_piece_jointe_103){'piece_jointe_103.pdf'}
    let(:name_piece_jointe_692){'piece_jointe_692.pdf'}

    let(:cerfa_pdf) {Rack::Test::UploadedFile.new("./spec/support/files/#{name_piece_jointe}", 'application/pdf')}
    let(:piece_jointe_103) {Rack::Test::UploadedFile.new("./spec/support/files/#{name_piece_jointe_103}", 'application/pdf')}
    let(:piece_jointe_692) {Rack::Test::UploadedFile.new("./spec/support/files/#{name_piece_jointe_692}", 'application/pdf')}


    context 'Tous les attributs sont bons' do
      #TODO separer en deux tests : check donnees et check redirect
      it 'Premier enregistrement des données' do
        post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact
        expect(response).to redirect_to("/dossiers/#{dossier_id}/recapitulatif")
      end

      #TODO changer les valeurs des champs et check in bdd
      context 'En train de modifier les données de description du projet' do
        before do
          post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact, :back_url => 'recapitulatif'
        end

        context 'Enregistrement d\'un commentaire informant la modification' do
          subject{Commentaire.last}

          it 'champs email' do
            expect(subject.email).to eq('Modification détails')
          end

          it 'champs body' do
            expect(subject.body).to eq('Les informations détaillées de la demande ont été modifiées. Merci de le prendre en compte.')
          end

          it 'champs dossier' do
            expect(subject.dossier.id).to eq(dossier_id)
          end
        end

        it 'Redirection vers la page récapitulatif' do
          expect(response).to redirect_to("/dossiers/#{dossier_id}/recapitulatif")
        end
      end
    end

    context 'Attribut(s) manquant(s)' do
      it 'nom_projet manquant' do
        post :create, :dossier_id => dossier_id, :nom_projet => '', :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact
        expect(response).to redirect_to("/dossiers/#{dossier_id}/description/error")
      end

      it 'description manquante' do
        post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => '', :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact
        expect(response).to redirect_to("/dossiers/#{dossier_id}/description/error")
      end

      it 'montant_projet manquant' do
        post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => '', :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact
        expect(response).to redirect_to("/dossiers/#{dossier_id}/description/error")
      end

      it 'montant_aide_demande manquant' do
        post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => '', :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact
        expect(response).to redirect_to("/dossiers/#{dossier_id}/description/error")
      end

      it 'date_previsionnelle manquante' do
        post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => '', :mail_contact => mail_contact
        expect(response).to redirect_to("/dossiers/#{dossier_id}/description/error")
      end

      it 'mail_contact manquant' do
        post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => ''
        expect(response).to redirect_to("/dossiers/#{dossier_id}/description/error")
      end
    end

    context 'Mauvais format(s)' do
      it 'mail_contact n\'est un format d\'email' do
        post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => 'test.com'
        expect(response).to redirect_to("/dossiers/#{dossier_id}/description/error")
      end
    end

    context 'Sauvegarde du CERFA PDF' do
      before do
        post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact, :cerfa_pdf => cerfa_pdf
      end

      context 'un CERFA PDF est envoyé' do
        subject{PieceJointe.last}
        it 'content' do
          expect(subject['content']).to eq(name_piece_jointe)
        end

        it 'dossier_id' do
          expect(subject.dossier_id).to eq(dossier_id)
        end

        it 'ref_pieces_jointes_id' do
          expect(subject.ref_pieces_jointes_id).to eq(0)
        end
      end

      context 'les anciens CERFA PDF sont écrasées à chaque fois' do
        it 'il n\'y a qu\'un CERFA PDF par dossier' do
          post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact, :cerfa_pdf => cerfa_pdf
          cerfa = PieceJointe.where(ref_pieces_jointes_id: '0', dossier_id: dossier_id)
          expect(cerfa.many?).to eq(false)
        end
      end

      context 'pas de CERFA PDF' do
        #TODO à écrire
      end
    end

    context 'Sauvegarde des pièces jointes' do
      before do
        post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact, :piece_jointe_692 => piece_jointe_692, :piece_jointe_103 => piece_jointe_103
      end

      context 'sauvegarde de 2 pieces jointes' do
        it 'les deux pièces sont présentes en base' do
          piece_jointe_1 = PieceJointe.where(ref_pieces_jointes_id: '103', dossier_id: dossier_id)
          piece_jointe_2 = PieceJointe.where(ref_pieces_jointes_id: '692', dossier_id: dossier_id)

          expect(piece_jointe_1.first['content']).to eq(name_piece_jointe_103)
          expect(piece_jointe_2.first['content']).to eq(name_piece_jointe_692)
        end

        # TODO: refactor
        context  'les pièces sont ecrasées à chaque fois' do
          it 'il n\'y a qu\'une pièce jointe par type par dossier' do
            post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact, :piece_jointe_692 => piece_jointe_692, :piece_jointe_103 => piece_jointe_103

            piece_jointe_1 = PieceJointe.where(ref_pieces_jointes_id: '103', dossier_id: dossier_id)
            piece_jointe_2 = PieceJointe.where(ref_pieces_jointes_id: '692', dossier_id: dossier_id)

            expect(piece_jointe_1.many?).to eq(false)
            expect(piece_jointe_2.many?).to eq(false)
          end
        end
      end
    end
  end
end
