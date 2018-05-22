require 'spec_helper'

describe Users::RegistrationsController, type: :controller do
  let(:email) { 'test@octo.com' }
  let(:password) { 'password' }

  let(:user) { { email: email, password: password } }

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe '#create' do
    subject do
      post :create, params: { user: user }
    end

    context 'when user is correct' do
      it 'sends confirmation instruction' do
        expect(DeviseUserMailer).to receive(:confirmation_instructions).and_return(DeviseUserMailer)
        expect(DeviseUserMailer).to receive(:deliver)

        subject
      end
    end

    context 'when user is not correct' do
      let(:user) { { email: '', password: password } }

      it 'not sends confirmation instruction' do
        expect(DeviseUserMailer).not_to receive(:confirmation_instructions)

        subject
      end
    end
  end
end
