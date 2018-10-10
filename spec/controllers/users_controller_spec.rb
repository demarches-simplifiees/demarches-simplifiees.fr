require 'spec_helper'

require 'controllers/users_controller_shared_example'

describe UsersController, type: :controller do
  describe '#current_user_dossier' do
    let(:owner_user) { create(:user) }
    let(:invite_user) { create :user, email: 'invite@plop.com' }
    let(:not_invite_user) { create :user, email: 'not_invite@plop.com' }

    let(:dossier) { create(:dossier, user: owner_user) }

    context 'when user is the owner' do
      before do
        sign_in owner_user
      end

      it_should_behave_like "current_user_dossier_spec"
    end

    context 'when user is invite by the owner' do
      before do
        create :invite, email: invite_user.email, dossier: dossier, user: invite_user
        sign_in invite_user
      end

      it_should_behave_like "current_user_dossier_spec"
    end
  end
end
