require 'spec_helper'

describe Users::ProfilesController, type: :controller do
  let(:user) { create(:user) }
  let(:sally) { create(:user) }
  let(:picture) { Rack::Test::UploadedFile.new('./spec/support/files/profile.jpg', 'image/jpeg') }

  before do
    sign_in user
  end

  describe "#GET show" do
    it "any user profile page" do
      get :show, user_id: sally.id
      expect(response.status).to be(200)
    end
  end

  describe "#GET edit" do
    it "current user profile" do
      get :edit
      expect(response.status).to be(200)
    end
  end

  describe "#PATCH update" do
    it "current user profile" do
      patch :update, user: {
        gender: "male",
        family_name: "Smith",
        given_name: "John",
        entreprise_siret: "750123456",
        birthdate: "1979-10-31",
      }
      expect(response).to redirect_to(user_profile_path(user))
      user.reload
      expect(user.gender).to eq("male")
      expect(user.family_name).to eq("Smith")
      expect(user.given_name).to eq("John")
      expect(user.entreprise_siret).to eq("750123456")
      expect(user.birthdate).to eq(Date.new(1979, 10, 31))
    end

    it "won't change certified" do
      patch :update, user: { certified: true }
      expect(user.reload.certified).to be(false)
    end

    it "uploads profile picture for current user" do
      VCR.use_cassette("post_user_profile_picture") do
        patch :update, user: { picture: picture }
      end
      expect(response).to redirect_to(user_profile_path(user))
      expect(user.picture?).to be(false)
    end
  end

  describe "#DELETE destroy" do
    let(:user) do
      VCR.use_cassette("post_user_profile_picture") do
        create(:user, picture: picture)
      end
    end

    it "picture of current user" do
      VCR.use_cassette("delete_user_profile_picture") do
        delete :destroy
      end
      expect(response).to redirect_to(edit_users_profile_path)
      expect(user.picture?).to be(false)
    end
  end
end
