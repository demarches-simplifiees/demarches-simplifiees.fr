require 'spec_helper'

describe Users::RegistrationsController, type: :controller do

  let(:email) { 'test@octo.com' }
  let(:password) { 'password' }

  let(:user) { { email: email, password: password, password_confirmation: password } }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '.create' do
    subject { post :create, user: user }

    it { expect(described_class).to be < Devise::RegistrationsController }

    it 'welcome email is send' do
      expect(WelcomeMailer).to receive(:welcome_email).and_return(WelcomeMailer)
      expect(WelcomeMailer).to receive(:deliver_now!)

      subject
    end
  end
end
