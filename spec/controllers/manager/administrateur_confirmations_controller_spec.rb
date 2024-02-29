require 'rails_helper'

RSpec.describe Manager::AdministrateurConfirmationsController, type: :controller do
  let(:inviter_super_admin) { create(:super_admin) }
  let(:inviter_administrateur) { create(:administrateur, email: inviter_super_admin.email) }

  let(:invited_super_admin) { create(:super_admin) }
  let(:invited_administrateur) { create(:administrateur, email: invited_super_admin.email) }

  let(:confirmer_super_admin) { create(:super_admin) }

  let(:procedure) { create(:procedure, administrateurs: [inviter_administrateur]) }

  describe "GET #new" do
    subject(:new_request) do
      get :new, params: {
        procedure_id: procedure.id,
        q: encrypt({ email: invited_administrateur.email, inviter_id: inviter_super_admin.id })
      }
    end

    shared_examples "current admin is allowed to confirm adding another one" do
      before { new_request }

      it { expect(response).to render_template(:new) }
    end

    shared_examples "current admin isn't allowed to confirm adding another one" do
      before { new_request }

      it { expect(flash[:alert]).to match(/Veuillez partager ce lien avec un autre super administrateur/) }

      it { expect(response).to redirect_to(manager_procedure_path(procedure)) }
    end

    context 'when the current admin is the invited' do
      before { sign_in invited_super_admin }

      it_behaves_like "current admin isn't allowed to confirm adding another one"
    end

    context 'when the current admin is the inviter' do
      before { sign_in inviter_super_admin }

      it_behaves_like "current admin isn't allowed to confirm adding another one"
    end

    context 'when the current admin is not the invited nor the inviter' do
      before { sign_in confirmer_super_admin }

      it_behaves_like "current admin is allowed to confirm adding another one"
    end

    describe 'edge cases' do
      context 'when the environment is development' do
        before { allow(Rails.env).to receive(:development?).and_return(true) }

        context 'when the current admin is the inviter' do
          before { sign_in inviter_super_admin }

          it_behaves_like "current admin is allowed to confirm adding another one"
        end

        context 'when the current admin is the invited' do
          before { sign_in invited_super_admin }

          it_behaves_like "current admin is allowed to confirm adding another one"
        end
      end

      context 'when the encrypted params are invalid' do
        before { sign_in inviter_super_admin }
        before { get :new, params: { procedure_id: procedure.id, q: "something that is invalid" } }

        it { expect(flash[:error]).to match(/Le lien que vous avez utilisé est invalide/) }
      end
    end
  end

  describe "GET #create" do
    subject(:create_request) do
      post :create, params: {
        procedure_id: procedure.id,
        q: encrypt({ email: invited_administrateur.email, inviter_id: inviter_super_admin.id })
      }
    end

    shared_examples "current admin is allowed to confirm adding another one" do
      it "flashes the success message" do
        create_request
        expect(flash[:notice]).to include(invited_administrateur.email)
        expect(flash[:notice]).to match(/ajouté à la démarche/)
      end

      it "adds the admin to the procedure" do
        expect { create_request }.to change { procedure.administrateurs.count }.by(1)
      end

      it "redirects to the procedure" do
        create_request
        expect(response).to redirect_to(manager_procedure_path(procedure))
      end
    end

    shared_examples "current admin isn't allowed to confirm adding another one" do
      before { create_request }

      it { expect(flash[:alert]).to match(/Veuillez partager ce lien avec un autre super administrateur/) }

      it { expect(response).to redirect_to(manager_procedure_path(procedure)) }
    end

    context 'when the current admin is the invited' do
      before { sign_in invited_super_admin }

      it_behaves_like "current admin isn't allowed to confirm adding another one"
    end

    context 'when the current admin is the inviter' do
      before { sign_in inviter_super_admin }

      it_behaves_like "current admin isn't allowed to confirm adding another one"
    end

    context 'when the current admin is not the invited nor the inviter' do
      before { sign_in confirmer_super_admin }

      it_behaves_like "current admin is allowed to confirm adding another one"
    end

    describe 'edge cases' do
      context 'when the environment is development' do
        before { allow(Rails.env).to receive(:development?).and_return(true) }

        context 'when the current admin is the inviter' do
          before { sign_in inviter_super_admin }

          it_behaves_like "current admin is allowed to confirm adding another one"
        end

        context 'when the current admin is the invited' do
          before { sign_in invited_super_admin }

          it_behaves_like "current admin is allowed to confirm adding another one"
        end
      end

      context 'when the encrypted params are invalid' do
        before { sign_in inviter_super_admin }
        before { post :create, params: { procedure_id: procedure.id, q: "something that is invalid" } }

        it { expect(flash[:error]).to match(/Le lien que vous avez utilisé est invalide/) }
      end
    end
  end

  private

  def encrypt(parameters)
    key = Rails.application.key_generator.generate_key("confirm_adding_administrateur")
    verifier = ActiveSupport::MessageVerifier.new(key)
    Base64.urlsafe_encode64(verifier.generate(parameters))
  end
end
