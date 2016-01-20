require 'spec_helper'

describe Users::RegistrationsController, type: :controller do

  let(:email) { 'test@octo.com' }
  let(:password) { 'password' }

  let(:user) { {email: email, password: password, password_confirmation: password} }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '.create' do
    subject { post :create, user: user }

    context 'when user is correct' do
      it { expect(described_class).to be < Devise::RegistrationsController }

      it 'sends welcome email' do
        expect(WelcomeMailer).to receive(:welcome_email).and_return(WelcomeMailer)
        expect(WelcomeMailer).to receive(:deliver_now!)

        subject
      end
    end

    context 'when user is not correct' do
      let(:user) { {email: '', password: password, password_confirmation: password} }

      it 'not sends welcome email' do
        expect(WelcomeMailer).not_to receive(:welcome_email)

        subject
      end
    end
  end
end
