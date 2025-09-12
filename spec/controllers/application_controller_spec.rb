# frozen_string_literal: true

describe ApplicationController, type: :controller do
  describe 'before_action: set_sentry_user' do
    it 'is present' do
      before_actions = ApplicationController
        ._process_action_callbacks
        .filter { |process_action_callbacks| process_action_callbacks.kind == :before }
        .map(&:filter)

      expect(before_actions).to include(:set_sentry_user)
      expect(before_actions).to include(:redirect_if_untrusted)
    end
  end

  describe 'set_sentry_user and append_info_to_payload' do
    let(:current_user) { nil }
    let(:current_instructeur) { nil }
    let(:current_administrateur) { nil }
    let(:current_super_admin) { nil }
    let(:payload) { {} }

    before do
      allow(@controller).to receive(:media_type).and_return('text/plain')
      allow(@controller).to receive(:current_user).and_return(current_user)
      expect(@controller).to receive(:current_instructeur).and_return(current_instructeur)
      expect(@controller).to receive(:current_administrateur).at_least(:once).and_return(current_administrateur)
      expect(@controller).to receive(:current_super_admin).and_return(current_super_admin)
      allow(Sentry).to receive(:set_user)

      @controller.send(:set_sentry_user)
      @controller.send(:append_info_to_payload, payload)
    end

    context 'when no one is logged in' do
      it do
        expect(Sentry).to have_received(:set_user)
          .with({ id: 'Guest' })
      end

      it do
        [:db_runtime, :view_runtime, :variant, :rendered_format].each do |key|
          payload.delete(key)
        end
        expect(payload[:to_log].compact).to eq({
          user_agent: 'Rails Testing',
          user_roles: 'Guest',
          db_queries_count: 0
        })
      end
    end

    context 'when a user is logged in' do
      let(:current_user) { create(:user) }

      it do
        expect(Sentry).to have_received(:set_user)
          .with({ id: "User##{current_user.id}" })
      end

      it do
        [:db_runtime, :view_runtime, :variant, :rendered_format].each do |key|
          payload.delete(key)
        end
        expect(payload[:to_log].compact).to eq({
          user_agent: 'Rails Testing',
          user_id: current_user.id,
          user_roles: 'User',
          db_queries_count: 0
        })
      end
    end

    context 'when someone is logged as a user, instructeur, administrateur and super_admin' do
      let(:current_user) { create(:user) }
      let(:current_instructeur) { create(:instructeur) }
      let(:current_administrateur) { administrateurs(:default_admin) }
      let(:current_super_admin) { create(:super_admin) }

      it do
        expect(Sentry).to have_received(:set_user)
          .with({ id: "User##{current_user.id}" })
      end

      it do
        [:db_runtime, :view_runtime, :variant, :rendered_format].each do |key|
          payload.delete(key)
        end
        expect(payload[:to_log].compact).to eq({
          user_agent: 'Rails Testing',
          user_id: current_user.id,
          user_roles: 'User, Instructeur, Administrateur, SuperAdmin',
          db_queries_count: 0
        })
      end
    end
  end

  describe 'reject before action' do
    let(:path_info) { '/one_path' }

    before do
      allow(@controller).to receive(:redirect_to)
      allow(@controller).to receive(:sign_out)
      allow(@controller).to receive(:render)
      @request.path_info = path_info
    end

    context 'when no super_admin is logged in' do
      before { @controller.send(:reject) }

      it { expect(@controller).to have_received(:sign_out).with(:user) }
      it { expect(@controller).to have_received(:sign_out).with(:instructeur) }
      it { expect(@controller).to have_received(:sign_out).with(:administrateur) }
      it { expect(flash[:alert]).to eq(ApplicationController::MAINTENANCE_MESSAGE) }
      it { expect(@controller).to have_received(:redirect_to).with(root_path) }

      context 'when the path is safe' do
        ['/', '/manager', '/super_admins'].each do |path|
          let(:path_info) { path }

          it { expect(@controller).not_to have_received(:sign_out) }
          it { expect(@controller).not_to have_received(:redirect_to) }
          it { expect(flash.alert).to eq(ApplicationController::MAINTENANCE_MESSAGE) }
        end
      end

      context 'when the path is api related' do
        let(:path_info) { '/api/some-stuff' }
        let(:json_error) { { error: ApplicationController::MAINTENANCE_MESSAGE }.to_json }
        it { expect(@controller).not_to have_received(:sign_out) }
        it { expect(@controller).not_to have_received(:redirect_to) }
        it { expect(flash.alert).to be_nil }
        it { expect(@controller).to have_received(:render).with({ json: json_error, status: :service_unavailable }) }
      end
    end

    context 'when a super_admin is logged in' do
      let(:current_super_admin) { create(:super_admin) }

      before do
        sign_in(current_super_admin)
        @controller.send(:reject)
      end

      it { expect(@controller).not_to have_received(:sign_out) }
      it { expect(@controller).not_to have_received(:redirect_to) }
      it { expect(flash[:alert]).to eq(ApplicationController::MAINTENANCE_MESSAGE) }
    end
  end

  describe '#redirect_if_unstrusted' do
    let(:current_instructeur) { create(:instructeur) }

    before do
      allow(@controller).to receive(:current_instructeur).and_return(current_instructeur)
      allow(@controller).to receive(:redirect_to)
      allow(@controller).to receive(:trusted_device?).and_return(trusted_device)
      allow(@controller).to receive(:instructeur_signed_in?).and_return(instructeur_signed_in)
      allow(@controller).to receive(:sensitive_path).and_return(sensitive_path)
      allow(@controller).to receive(:send_login_token_or_bufferize)
      allow(@controller).to receive(:get_stored_location_for).and_return(nil)
      allow(@controller).to receive(:store_location_for)
      allow(IPService).to receive(:ip_trusted?).and_return(ip_trusted)
    end

    subject { @controller.send(:redirect_if_untrusted) }

    context 'when the path is sensitive' do
      let(:sensitive_path) { true }

      before do
        current_instructeur.update!(bypass_email_login_token: false)
      end

      context 'when the instructeur is signed_in' do
        let(:instructeur_signed_in) { true }

        context 'when the ip is not trusted' do
          let(:ip_trusted) { false }

          context 'when the device is trusted' do
            let(:trusted_device) { true }

            before { subject }

            it { expect(@controller).not_to have_received(:redirect_to) }
          end

          context 'when the device is not trusted' do
            let(:trusted_device) { false }

            before { subject }

            it { expect(@controller).to have_received(:redirect_to) }
            it { expect(@controller).to have_received(:send_login_token_or_bufferize) }
            it { expect(@controller).to have_received(:store_location_for) }
          end
        end

        context 'when the ip is trusted' do
          let(:ip_trusted) { true }

          context 'when the device is not trusted' do
            let(:trusted_device) { false }

            before { subject }

            it { expect(@controller).not_to have_received(:redirect_to) }
          end
        end
      end
    end
  end
end
