require 'spec_helper'

RSpec.describe DescriptionController, type: :controller do
  let (:dossier_id){10000}
  let (:bad_dossier_id){1000}

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
    let(:dossier_pdf) {''}
    
    context 'Tous les attributs sont bons' do
      it 'Premier enregistrement des données' do
        post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact
        expect(response).to redirect_to("/dossiers/#{dossier_id}/recapitulatif")
      end

      context 'En train de modifier les données de description du projet' do
        before do
          post :create, :dossier_id => dossier_id, :nom_projet => nom_projet, :description => description, :montant_projet => montant_projet, :montant_aide_demande => montant_aide_demande, :date_previsionnelle => date_previsionnelle, :mail_contact => mail_contact, :back_url => 'recapitulatif'
          @last_commentaire_id = ActiveRecord::Base.connection.execute("SELECT currval('commentaires_id_seq')").getvalue(0,0)
        end

        context 'Enregistrement d\'un commentaire informant la modification' do
          subject{Commentaire.find(@last_commentaire_id)}

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
  end
end
