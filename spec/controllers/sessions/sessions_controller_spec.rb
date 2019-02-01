require 'spec_helper'

describe Sessions::SessionsController, type: :controller do
  controller Sessions::SessionsController do
    def create
      render json: ''
    end
  end

  let(:user) { create(:user) }
  let(:gestionnaire) { create(:gestionnaire) }
  let(:administrateur) { create(:administrateur) }

  describe '#create' do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
    end

    it 'calls before_sign_in' do
      expect_any_instance_of(Sessions::SessionsController).to receive(:before_sign_in)
      post :create
    end
  end

  describe '#create with user connected' do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]

      allow_any_instance_of(described_class).to receive(:user_signed_in?).and_return(true)
    end

    it 'calls sign out for user' do
      expect_any_instance_of(described_class).to receive(:sign_out).with(:user)
      post :create
    end
  end

  describe '#create with gestionnaire connected' do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:gestionnaire]

      allow_any_instance_of(described_class).to receive(:gestionnaire_signed_in?).and_return(true)
      allow_any_instance_of(described_class).to receive(:current_gestionnaire).and_return(gestionnaire)
    end

    it 'calls sign out for gestionnaire' do
      expect_any_instance_of(described_class).to receive(:sign_out).with(:gestionnaire)
      post :create
    end
  end

  describe '#create with administrateur connected' do
    before do
      @request.env["devise.mapping"] = Devise.mappings[:administrateur]

      allow_any_instance_of(described_class).to receive(:administrateur_signed_in?).and_return(true)
    end

    it 'calls sign out for administrateur' do
      expect_any_instance_of(described_class).to receive(:sign_out).with(:administrateur)
      post :create
    end
  end
end
