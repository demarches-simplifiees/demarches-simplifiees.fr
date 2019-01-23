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
      subject do
        post :create, params: { subject: 'bonjour', text: 'un message' }
      end

      it 'creates a conversation on HelpScout' do
        expect_any_instance_of(Helpscout::FormAdapter).to receive(:send_form).and_return(true)

        expect { subject }.to change(Commentaire, :count).by(0)

        expect(flash[:notice]).to match('Votre message a été envoyé.')
        expect(response).to redirect_to root_path(formulaire_contact_general_submitted: true)
      end

      context 'when a drafted dossier is mentionned' do
        let(:dossier) { create(:dossier) }
        let(:user) { dossier.user }

        subject do
          post :create, params: {
            dossier_id: dossier.id,
            type: Helpscout::FormAdapter::TYPE_INSTRUCTION,
            subject: 'bonjour',
            text: 'un message'
          }
        end

        it 'creates a conversation on HelpScout' do
          expect_any_instance_of(Helpscout::FormAdapter).to receive(:send_form).and_return(true)

          expect { subject }.to change(Commentaire, :count).by(0)

          expect(flash[:notice]).to match('Votre message a été envoyé.')
          expect(response).to redirect_to root_path(formulaire_contact_general_submitted: true)
        end
      end

      context 'when a submitted dossier is mentionned' do
        let(:dossier) { create(:dossier, :en_construction) }
        let(:user) { dossier.user }

        subject do
          post :create, params: {
            dossier_id: dossier.id,
            type: Helpscout::FormAdapter::TYPE_INSTRUCTION,
            subject: 'bonjour',
            text: 'un message'
          }
        end

        it 'posts the message to the dossier messagerie' do
          expect_any_instance_of(Helpscout::FormAdapter).not_to receive(:send_form)

          expect { subject }.to change(Commentaire, :count).by(1)

          expect(Commentaire.last.email).to eq(user.email)
          expect(Commentaire.last.dossier).to eq(dossier)
          expect(Commentaire.last.body).to include('[bonjour]')
          expect(Commentaire.last.body).to include('un message')

          expect(flash[:notice]).to match('Votre message a été envoyé sur la messagerie de votre dossier.')
          expect(response).to redirect_to messagerie_dossier_path(dossier)
        end
      end
    end
  end

  context 'signed out' do
    describe "with dossier" do
      it 'should have email field' do
        get :index

        expect(response.status).to eq(200)
        expect(response.body).to have_text("Email")
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
