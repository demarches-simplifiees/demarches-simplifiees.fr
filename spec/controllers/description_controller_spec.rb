require 'spec_helper'

describe Users::DescriptionController, type: :controller do
  let(:dossier) { create(:dossier, :with_procedure) }
  let(:dossier_id) { dossier.id }
  let(:bad_dossier_id) { Dossier.count + 10 }

  describe 'GET #show' do
    it 'returns http success' do
      get :show, dossier_id: dossier_id
      expect(response).to have_http_status(:success)
    end

    it 'redirection vers start si mauvais dossier ID' do
      get :show, dossier_id: bad_dossier_id
      expect(response).to redirect_to(controller: :siret)
    end
  end

  describe 'POST #create' do
    let(:timestamp) { Time.now }
    let(:nom_projet) { 'Projet de test' }
    let(:description) { 'Description de test Coucou, je suis un saut à la ligne Je suis un double saut  la ligne.' }
    let(:montant_projet) { 12_000 }
    let(:montant_aide_demande) { 3000 }
    let(:date_previsionnelle) { '20/01/2016' }

    let(:name_piece_justificative) { 'dossierPDF.pdf' }
    let(:name_piece_justificative_0) { 'piece_justificative_0.pdf' }
    let(:name_piece_justificative_1) { 'piece_justificative_1.pdf' }

    let(:cerfa_pdf) { Rack::Test::UploadedFile.new("./spec/support/files/#{name_piece_justificative}", 'application/pdf') }
    let(:piece_justificative_0) { Rack::Test::UploadedFile.new("./spec/support/files/#{name_piece_justificative_0}", 'application/pdf') }
    let(:piece_justificative_1) { Rack::Test::UploadedFile.new("./spec/support/files/#{name_piece_justificative_1}", 'application/pdf') }

    context 'Tous les attributs sont bons' do
      # TODO separer en deux tests : check donnees et check redirect
      it 'Premier enregistrement des données' do
        post :create, dossier_id: dossier_id, nom_projet: nom_projet, description: description, montant_projet: montant_projet, montant_aide_demande: montant_aide_demande, date_previsionnelle: date_previsionnelle
        expect(response).to redirect_to("/users/dossiers/#{dossier_id}/recapitulatif")
      end

      # TODO changer les valeurs des champs et check in bdd
      context 'En train de modifier les données de description du projet' do
        before do
          post :create, dossier_id: dossier_id, nom_projet: nom_projet, description: description, montant_projet: montant_projet, montant_aide_demande: montant_aide_demande, date_previsionnelle: date_previsionnelle, back_url: 'recapitulatif'
        end

        context 'Enregistrement d\'un commentaire informant la modification' do
          subject { Commentaire.last }

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
          expect(response).to redirect_to("/users/dossiers/#{dossier_id}/recapitulatif")
        end
      end
    end

    context 'Attribut(s) manquant(s)' do
      subject {
        post :create,
            dossier_id: dossier_id,
            nom_projet: nom_projet,
            description: description,
            montant_projet: montant_projet,
            montant_aide_demande: montant_aide_demande,
            date_previsionnelle: date_previsionnelle
      }
      before { subject }

      context 'nom_projet empty' do
        let(:nom_projet) { '' }
        it { is_expected.to render_template(:show) }
        it { expect(flash[:alert]).to be_present }
      end

      context 'description empty' do
        let(:description) { '' }
        it { is_expected.to render_template(:show) }
        it { expect(flash[:alert]).to be_present }
      end

      context 'montant_projet empty' do
        let(:montant_projet) { '' }
        it { is_expected.to render_template(:show) }
        it { expect(flash[:alert]).to be_present }
      end

      context 'montant_aide_demande empty' do
        let(:montant_aide_demande) { '' }
        it { is_expected.to render_template(:show) }
        it { expect(flash[:alert]).to be_present }
      end

      context 'date_previsionnelle empty' do
        let(:date_previsionnelle) { '' }
        it { is_expected.to render_template(:show) }
        it { expect(flash[:alert]).to be_present }
      end
    end

    context 'Sauvegarde du CERFA PDF' do
      before do
        post :create, dossier_id: dossier_id,
                      nom_projet: nom_projet,
                      description: description,
                      montant_projet: montant_projet,
                      montant_aide_demande: montant_aide_demande,
                      date_previsionnelle: date_previsionnelle,
                      cerfa_pdf: cerfa_pdf
        dossier.reload
      end

      context 'un CERFA PDF est envoyé' do
        subject { dossier.cerfa }
        it 'content' do
          expect(subject['content']).to eq(name_piece_justificative)
        end

        it 'dossier_id' do
          expect(subject.dossier_id).to eq(dossier_id)
        end
      end

      context 'les anciens CERFA PDF sont écrasées à chaque fois' do
        it 'il n\'y a qu\'un CERFA PDF par dossier' do
          post :create, dossier_id: dossier_id, nom_projet: nom_projet, description: description, montant_projet: montant_projet, montant_aide_demande: montant_aide_demande, date_previsionnelle: date_previsionnelle, cerfa_pdf: cerfa_pdf
          cerfa = PieceJustificative.where(type_de_piece_justificative_id: '0', dossier_id: dossier_id)
          expect(cerfa.many?).to eq(false)
        end
      end

      context 'pas de CERFA PDF' do
        # TODO à écrire
      end
    end

    context 'Sauvegarde des pièces justificatives' do
      let(:all_pj_type){ dossier.procedure.type_de_piece_justificative_ids }
      before do
        post :create, {dossier_id: dossier_id,
                      nom_projet: nom_projet,
                      description: description,
                      montant_projet: montant_projet,
                      montant_aide_demande: montant_aide_demande,
                      date_previsionnelle: date_previsionnelle,
                      'piece_justificative_'+all_pj_type[0].to_s => piece_justificative_0,
                      'piece_justificative_'+all_pj_type[1].to_s => piece_justificative_1}
        dossier.reload
      end

      context 'for piece 0' do
        subject { dossier.retrieve_piece_justificative_by_type all_pj_type[0].to_s }
        it { expect(subject.content).not_to be_nil }
      end
      context 'for piece 1' do
        subject { dossier.retrieve_piece_justificative_by_type all_pj_type[1].to_s }
        it { expect(subject.content).not_to be_nil }
      end
    end
  end
end
