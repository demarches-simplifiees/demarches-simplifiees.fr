require 'spec_helper'

describe ApplicationController, type: :controller do
  describe 'before_action: set_raven_context' do
    it 'is present' do
      before_actions = ApplicationController
        ._process_action_callbacks
        .find_all{ |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:set_raven_context)
    end
  end

  describe 'set_raven_context' do
    let(:current_user) { nil }
    let(:current_gestionnaire) { nil }
    let(:current_administrateur) { nil }
    let(:current_administration) { nil }

    before do
      expect(@controller).to receive(:current_user).and_return(current_user)
      expect(@controller).to receive(:current_gestionnaire).and_return(current_gestionnaire)
      expect(@controller).to receive(:current_administrateur).and_return(current_administrateur)
      expect(@controller).to receive(:current_administration).and_return(current_administration)
      allow(Raven).to receive(:user_context)

      @controller.send(:set_raven_context)
    end

    context 'when no one is logged in' do
      it do
        expect(Raven).to have_received(:user_context)
          .with({ ip_address: '0.0.0.0', email: nil, id: nil, classes: 'Guest' })
      end
    end

    context 'when a user is logged in' do
      let(:current_user) { create(:user) }

      it do
        expect(Raven).to have_received(:user_context)
          .with({ ip_address: '0.0.0.0', email: current_user.email, id: current_user.id, classes: 'User' })
      end
    end

    context 'when someone is logged as a user, gestionnaire, administrateur and administration' do
      let(:current_user) { create(:user) }
      let(:current_gestionnaire) { create(:gestionnaire) }
      let(:current_administrateur) { create(:administrateur) }
      let(:current_administration) { create(:administration) }

      it do
        expect(Raven).to have_received(:user_context)
          .with({ ip_address: '0.0.0.0', email: current_user.email, id: current_user.id, classes: 'User, Gestionnaire, Administrateur, Administration' })
      end
    end
  end
end
