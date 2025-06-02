# frozen_string_literal: true

describe DevisePopulatedResource, type: :controller do
  controller(Devise::PasswordsController) do
    include DevisePopulatedResource
    layout false
  end

  let(:user) { create(:user) }

  before do
    routes.draw do
      get 'edit' => 'devise/passwords#edit'
      put 'update' => 'devise/passwords#update'
    end

    @request.env["devise.mapping"] = Devise.mappings[:user]

    @token = user.send_reset_password_instructions
  end

  context 'when initiating a password reset' do
    subject { get :edit, params: { reset_password_token: token } }

    context 'with a valid token' do
      let(:token) { @token }

      it 'returns the fully populated resource' do
        subject
        expect(controller.populated_resource.id).to eq(user.id)
        expect(controller.populated_resource.email).to eq(user.email)
      end
    end

    context 'with an expired token' do
      let(:token) { 'invalid-token' }

      it 'returns a new blank resource' do
        subject
        expect(controller.populated_resource).to be_present
        expect(controller.populated_resource.new_record?).to be(true)
        expect(controller.populated_resource.email).to be_blank
      end
    end
  end

  context 'when submitting a password reset' do
    subject { put :update, params: { user: { reset_password_token: @token } } }

    it 'returns the fully populated resource' do
      subject
      expect(controller.populated_resource.id).to eq(user.id)
      expect(controller.populated_resource.email).to eq(user.email)
    end
  end
end
