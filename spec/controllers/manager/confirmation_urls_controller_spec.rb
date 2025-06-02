# frozen_string_literal: true

describe Manager::ConfirmationUrlsController, type: :controller do
  let(:inviter_super_admin) { create(:super_admin) }
  let(:inviter_administrateur) { create(:administrateur, email: inviter_super_admin.email) }

  let(:invited_super_admin) { create(:super_admin) }
  let(:invited_administrateur) { create(:administrateur, email: invited_super_admin.email) }

  let(:procedure) { create(:procedure, administrateurs: [inviter_administrateur]) }

  before { sign_in inviter_super_admin }

  describe "#add_administrateur_with_confirmation" do
    render_views

    let(:params) do
      {
        procedure_id: procedure.id,
        email: invited_administrateur.email
      }
    end

    before { get :new, params: params }

    it { expect(response).to render_template(:new) }

    it { expect(response.body).to match(/Veuillez partager ce lien/) }

    it "shows the confirmation url with encrypted parameters" do
      expect(response.body).to include(
        new_manager_procedure_administrateur_confirmation_url(
          procedure,
          q: encrypt({ email: invited_administrateur.email, inviter_id: inviter_super_admin.id })
        )
      )
    end

    describe 'edge cases' do
      context 'when the administrateur does not exist' do
        let(:params) do
          {
            procedure_id: procedure.id,
            email: "wrong@email.com"
          }
        end

        it { expect(flash[:alert]).to match(/Cet administrateur n'existe pas/) }

        it { expect(response).to redirect_to(manager_procedure_path(procedure)) }
      end

      context 'when the administrateur has already been added to the procedure' do
        let(:params) do
          {
            procedure_id: procedure.id,
            email: inviter_super_admin.email
          }
        end

        it { expect(flash[:alert]).to match(/Cet administrateur a déjà été ajouté/) }

        it { expect(response).to redirect_to(manager_procedure_path(procedure)) }
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
