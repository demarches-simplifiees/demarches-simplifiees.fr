require 'spec_helper'

describe SupportController, type: :controller do
  render_views

  context 'signed in' do
    before do
      sign_in user
    end
    let(:user) { create(:user) }

    it 'should not have email field' do
      get :index

      expect(response.status).to eq(200)
      expect(response.body).not_to have_content("Email *")
    end

    describe "with dossier" do
      let(:user) { dossier.user }
      let(:dossier) { create(:dossier) }

      it 'should fill dossier_id' do
        get :index, params: { dossier_id: dossier.id }

        expect(response.status).to eq(200)
        expect(response.body).to include((dossier.id).to_s)
      end
    end

    describe "with tag" do
      let(:tag) { 'yolo' }

      it 'should fill tags' do
        get :index, params: { tags: [tag] }

        expect(response.status).to eq(200)
        expect(response.body).to include(tag)
      end
    end

    describe "with multiple tags" do
      let(:tags) { ['yolo', 'toto'] }

      it 'should fill tags' do
        get :index, params: { tags: tags }

        expect(response.status).to eq(200)
        expect(response.body).to include(tags.join(','))
      end
    end

    describe "send form" do
      it 'should create conversation' do
        expect(subject).not_to receive(:create_commentaire)
        allow(subject).to receive(:create_conversation).and_return(true)

        post :create, params: {
          subject: 'bonjour',
          text: 'un message'
        }

        expect(flash[:notice]).to match('Votre message a été envoyé.')
        expect(response).to redirect_to root_path(formulaire_contact_general_submitted: true)
      end

      context "with dossier" do
        let(:user) { dossier.user }
        let(:dossier) { create(:dossier) }

        it 'should create conversation' do
          expect(subject).not_to receive(:create_commentaire)
          allow(subject).to receive(:create_conversation).and_return(true)

          post :create, params: {
            dossier_id: dossier.id,
            type: Helpscout::FormAdapter::TYPE_INSTRUCTION,
            subject: 'bonjour',
            text: 'un message'
          }

          expect(flash[:notice]).to match('Votre message a été envoyé.')
          expect(response).to redirect_to root_path(formulaire_contact_general_submitted: true)
        end

        context "en_construction" do
          let(:dossier) { create(:dossier, :en_construction) }

          it 'should create commentaire' do
            allow(subject).to receive(:create_commentaire).and_return(true)
            expect(subject).not_to receive(:create_conversation)

            post :create, params: {
              dossier_id: dossier.id,
              type: Helpscout::FormAdapter::TYPE_INSTRUCTION,
              subject: 'bonjour',
              text: 'un message'
            }

            expect(flash[:notice]).to match('Votre message a été envoyé sur la messagerie de votre dossier.')
            expect(response).to redirect_to messagerie_dossier_path(dossier)
          end
        end
      end
    end
  end

  context 'signed out' do
    describe "with dossier" do
      it 'should have email field' do
        get :index

        expect(response.status).to eq(200)
        expect(response.body).to have_content("Email *")
      end
    end

    describe "with dossier" do
      let(:tag) { 'yolo' }

      it 'should fill tags' do
        get :index, params: { tags: [tag] }

        expect(response.status).to eq(200)
        expect(response.body).to include(tag)
      end
    end
  end
end
