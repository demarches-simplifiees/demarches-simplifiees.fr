require 'spec_helper'

describe DescriptionController, type: :controller do
  let(:dossier) { create(:dossier) }
  let(:dossier_id) { dossier.id }
  let(:bad_dossier_id) { Dossier.count + 10 }

  describe "GET #show" do
    it "returns http success" do
      get :show, dossier_id: dossier_id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers start si mauvais dossier ID' do
      get :show, dossier_id: bad_dossier_id
      expect(response).to redirect_to(controller: :start, action: :error_dossier)
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
        dossier.build_default_pieces_jointes
        post :create, :dossier_id => dossier_id,
                      :nom_projet => nom_projet,
                      :description => description,
                      :montant_projet => montant_projet,
                      :montant_aide_demande => montant_aide_demande,
                      :date_previsionnelle => date_previsionnelle,
                      :mail_contact => mail_contact,
                      :cerfa_pdf => cerfa_pdf
        dossier.reload
      end

      context 'un CERFA PDF est envoyé' do
        subject{ dossier.cerfa }
        it 'content' do
          expect(subject['content']).to eq(name_piece_jointe)
        end

        it 'dossier_id' do
          expect(subject.dossier_id).to eq(dossier_id)
        end
      end

      context 'les anciens CERFA PDF sont écrasées à chaque fois' do
        it 'il n\'y a qu\'un CERFA PDF par dossier' do
          post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact, :cerfa_pdf => cerfa_pdf
          cerfa = PieceJointe.where(type_piece_jointe_id: '0', dossier_id: dossier_id)
          expect(cerfa.many?).to eq(false)
        end
      end

      context 'pas de CERFA PDF' do
        #TODO à écrire
      end
    end

    context 'Sauvegarde des pièces jointes' do
      before do
        dossier.build_default_pieces_jointes
        post :create, :dossier_id => dossier_id,
                      :nom_projet => nom_projet,
                      :description => description,
                      :montant_projet => montant_projet,
                      :montant_aide_demande => montant_aide_demande,
                      :date_previsionnelle => date_previsionnelle,
                      :mail_contact => mail_contact,
                      :piece_jointe_692 => piece_jointe_692,
                      :piece_jointe_103 => piece_jointe_103
        dossier.reload
      end

      context 'for piece 692' do
        subject { dossier.retrieve_piece_jointe_by_type 692 }
        it { expect(subject.content).not_to be_nil }
      end
      context 'for piece 103' do
        subject { dossier.retrieve_piece_jointe_by_type 103 }
        it { expect(subject.content).not_to be_nil }
      end
    end
  end
end
