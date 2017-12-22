require 'spec_helper'

describe Administrations::OmniauthCallbacksController, type: :controller do
  before(:each) do
    @request.env["devise.mapping"] = Devise.mappings[:administration]
  end

  describe 'POST #github' do
    let(:params) { { "info" => { "email" => email } } }
    before do
      controller.stub(:sign_in).and_return true
      @request.env["omniauth.auth"] = params
    end
    subject { post :github }

    context 'with an authorized email' do
      let(:email) { "ivan@tps.fr" }
      let(:administration) { create(:administration, email: email) }
      before { administration }

      it { is_expected.to redirect_to(administrations_path) }
      it do
        expect(controller).to receive(:sign_in).with(administration)
        subject
      end
    end

    context 'with an unauthorized email' do
      let(:email) { "michel@tps.fr" }

      it { is_expected.to redirect_to(root_path) }
      it do
        expect(controller).to_not receive(:sign_in)
        subject
      end
    end
  end
end
