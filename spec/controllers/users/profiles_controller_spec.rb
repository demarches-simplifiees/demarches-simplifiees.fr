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
    let!(:profile) { create(:profile, user: user) }

    it "current user profile" do
      get :edit
      expect(response.status).to be(200)
    end
  end

  describe "#PATCH update" do
    it "current user profile" do
      profile = create(:profile, user: user)
      patch :update, profile: {
        gender: "male",
        family_name: "Smith",
        given_name: "John",
        entreprise_siret: "750123456",
        birthdate: "1979-10-31",
      }
      expect(response).to redirect_to(user_profile_path(user))
      profile.reload
      expect(profile.gender).to eq("male")
      expect(profile.family_name).to eq("Smith")
      expect(profile.given_name).to eq("John")
      expect(profile.entreprise_siret).to eq("750123456")
      expect(profile.birthdate).to eq(Date.new(1979, 10, 31))
    end

    it "creates missing profile" do
      patch :update, profile: { gender: "female" }
      expect(response).to redirect_to(user_profile_path(user))
      expect(user.profile).to be_truthy
      expect(user.profile.gender).to eq("female")
    end

    it "uploads profile picture for current user" do
      VCR.use_cassette("post_user_profile_picture") do
        patch :update, profile: { picture: picture }
      end
      expect(response).to redirect_to(user_profile_path(user))
      expect(user.profile[:picture]).to be_truthy
    end

    it "won't change certified" do
      patch :update, profile: { certified: true }
      expect(user.profile.reload.certified).to be(false)
    end
  end

  describe "#DELETE destroy" do
    let!(:profile) do
      VCR.use_cassette("post_user_profile_picture") do
        create(:profile, user: user, picture: picture)
      end
    end

    it "picture of current user" do
      VCR.use_cassette("delete_user_profile_picture") do
        delete :destroy
      end
      expect(response).to redirect_to(edit_users_profile_path)
      expect(profile.reload[:picture]).to be(nil)
    end
  end
end
