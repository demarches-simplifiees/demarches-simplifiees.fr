describe APIEntrepriseToken, type: :model do
  let(:api_entreprise_token) { APIEntrepriseToken.new(token) }

  describe "#token" do
    subject { api_entreprise_token.token }

    context "without token" do
      let(:token) { nil }
      # Pf : do not raise exception as api_entreprise_token is not defined
      # it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
      it { expect(subject).to be_nil }
    end

    context "with a blank token" do
      let(:token) { "" }
      # Pf : do not raise exception as api_entreprise_token is not defined
      # it { expect { subject }.to.not raise_exception(APIEntrepriseToken::TokenError) }
      it { expect(subject).to equal(token) }
    end

    context "with an invalid token" do
      let(:token) { "NOT-A-VALID-TOKEN" }

      it { expect(subject).to equal(token) }
    end

    context "with a valid token" do
      let(:token) { "eyJhbGciOiJIUzI1NiJ9.eyJ1aWQiOiI2NjRkZWEyMS02YWFlLTQwZmYtYWM0Mi1kZmQ3ZGE4YjQ3NmUiLCJqdGkiOiJhcGktZW50cmVwcmlzZS1zdGFnaW5nIiwicm9sZXMiOlsiY2VydGlmaWNhdF9jbmV0cCIsInByb2J0cCIsImV0YWJsaXNzZW1lbnRzIiwicHJpdmlsZWdlcyIsInVwdGltZSIsImF0dGVzdGF0aW9uc19hZ2VmaXBoIiwiYWN0ZXNfaW5waSIsImJpbGFuc19pbnBpIiwiYWlkZXNfY292aWRfZWZmZWN0aWZzIiwiY2VydGlmaWNhdF9yZ2VfYWRlbWUiLCJhdHRlc3RhdGlvbnNfc29jaWFsZXMiLCJlbnRyZXByaXNlX2FydGlzYW5hbGUiLCJmbnRwX2NhcnRlX3BybyIsImNvbnZlbnRpb25zX2NvbGxlY3RpdmVzIiwiZXh0cmFpdHNfcmNzIiwiZXh0cmFpdF9jb3VydF9pbnBpIiwiY2VydGlmaWNhdF9hZ2VuY2VfYmlvIiwibXNhX2NvdGlzYXRpb25zIiwiZG9jdW1lbnRzX2Fzc29jaWF0aW9uIiwiZW9yaV9kb3VhbmVzIiwiYXNzb2NpYXRpb25zIiwiYmlsYW5zX2VudHJlcHJpc2VfYmRmIiwiZW50cmVwcmlzZXMiLCJxdWFsaWJhdCIsImNlcnRpZmljYXRfb3BxaWJpIiwiZW50cmVwcmlzZSIsImV0YWJsaXNzZW1lbnQiXSwic3ViIjoic3RhZ2luZyBkZXZlbG9wbWVudCIsImlhdCI6MTY0MTMwNDcxNCwidmVyc2lvbiI6IjEuMCIsImV4cCI6MTY4ODQ3NTUxNH0.xID66pIlMnBR5_6nG-GidFBzK4Tuuy5ZsWfkMEVB_Ek" }

      it { expect(subject).to equal(token) }
    end
  end

  describe "#role?" do
    subject { api_entreprise_token.role?(role) }

    context "without token" do
      let(:token) { nil }
      let(:role) { "actes_inpi" }

      # Pf : do not raise exception as api_entreprise_token is not defined
      # it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
      it { expect(subject).to be_falsey }
    end

    context "with a blank token" do
      let(:token) { "" }
      let(:role) { "actes_inpi" }

      # Pf : do not raise exception as api_entreprise_token is not defined
      # it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
      it { expect(subject).to be_falsey }
    end

    context "with an invalid token" do
      let(:token) { "NOT-A-VALID-TOKEN" }
      let(:role) { "actes_inpi" }

      it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
    end

    context "with a valid token" do
      let(:token) { "eyJhbGciOiJIUzI1NiJ9.eyJ1aWQiOiI2NjRkZWEyMS02YWFlLTQwZmYtYWM0Mi1kZmQ3ZGE4YjQ3NmUiLCJqdGkiOiJhcGktZW50cmVwcmlzZS1zdGFnaW5nIiwicm9sZXMiOlsiY2VydGlmaWNhdF9jbmV0cCIsInByb2J0cCIsImV0YWJsaXNzZW1lbnRzIiwicHJpdmlsZWdlcyIsInVwdGltZSIsImF0dGVzdGF0aW9uc19hZ2VmaXBoIiwiYWN0ZXNfaW5waSIsImJpbGFuc19pbnBpIiwiYWlkZXNfY292aWRfZWZmZWN0aWZzIiwiY2VydGlmaWNhdF9yZ2VfYWRlbWUiLCJhdHRlc3RhdGlvbnNfc29jaWFsZXMiLCJlbnRyZXByaXNlX2FydGlzYW5hbGUiLCJmbnRwX2NhcnRlX3BybyIsImNvbnZlbnRpb25zX2NvbGxlY3RpdmVzIiwiZXh0cmFpdHNfcmNzIiwiZXh0cmFpdF9jb3VydF9pbnBpIiwiY2VydGlmaWNhdF9hZ2VuY2VfYmlvIiwibXNhX2NvdGlzYXRpb25zIiwiZG9jdW1lbnRzX2Fzc29jaWF0aW9uIiwiZW9yaV9kb3VhbmVzIiwiYXNzb2NpYXRpb25zIiwiYmlsYW5zX2VudHJlcHJpc2VfYmRmIiwiZW50cmVwcmlzZXMiLCJxdWFsaWJhdCIsImNlcnRpZmljYXRfb3BxaWJpIiwiZW50cmVwcmlzZSIsImV0YWJsaXNzZW1lbnQiXSwic3ViIjoic3RhZ2luZyBkZXZlbG9wbWVudCIsImlhdCI6MTY0MTMwNDcxNCwidmVyc2lvbiI6IjEuMCIsImV4cCI6MTY4ODQ3NTUxNH0.xID66pIlMnBR5_6nG-GidFBzK4Tuuy5ZsWfkMEVB_Ek" }

      context "but an unfetchable role" do
        let(:role) { "NOT-A-ROLE" }

        it { expect(subject).to be_falsey }
      end

      context "and a fetchable role" do
        let(:role) { "actes_inpi" }

        it { expect(subject).to be_truthy }
      end
    end
  end

  describe "#expired?" do
    subject { api_entreprise_token.expired? }

    context "without token" do
      let(:token) { nil }

      # Pf : do not raise exception as api_entreprise_token is not defined
      # it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
      it { expect(subject).to be_falsey }
    end

    context "with a blank token" do
      let(:token) { "" }

      # Pf : do not raise exception as api_entreprise_token is not defined
      # it { expect { subject }.to.not raise_exception(APIEntrepriseToken::TokenError) }
      it { expect(subject).to be_falsey }
    end

    context "with an invalid token" do
      let(:token) { "NOT-A-VALID-TOKEN" }

      it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
    end

    context "with a valid not expiring token" do
      # never expire
      let(:token) { "eyJhbGciOiJIUzI1NiJ9.eyJ1aWQiOiI2NjRkZWEyMS02YWFlLTQwZmYtYWM0Mi1kZmQ3ZGE4YjQ3NmUiLCJqdGkiOiJhcGktZW50cmVwcmlzZS1zdGFnaW5nIiwicm9sZXMiOlsiY2VydGlmaWNhdF9jbmV0cCIsInByb2J0cCIsImV0YWJsaXNzZW1lbnRzIiwicHJpdmlsZWdlcyIsInVwdGltZSIsImF0dGVzdGF0aW9uc19hZ2VmaXBoIiwiYWN0ZXNfaW5waSIsImJpbGFuc19pbnBpIiwiYWlkZXNfY292aWRfZWZmZWN0aWZzIiwiY2VydGlmaWNhdF9yZ2VfYWRlbWUiLCJhdHRlc3RhdGlvbnNfc29jaWFsZXMiLCJlbnRyZXByaXNlX2FydGlzYW5hbGUiLCJmbnRwX2NhcnRlX3BybyIsImNvbnZlbnRpb25zX2NvbGxlY3RpdmVzIiwiZXh0cmFpdHNfcmNzIiwiZXh0cmFpdF9jb3VydF9pbnBpIiwiY2VydGlmaWNhdF9hZ2VuY2VfYmlvIiwibXNhX2NvdGlzYXRpb25zIiwiZG9jdW1lbnRzX2Fzc29jaWF0aW9uIiwiZW9yaV9kb3VhbmVzIiwiYXNzb2NpYXRpb25zIiwiYmlsYW5zX2VudHJlcHJpc2VfYmRmIiwiZW50cmVwcmlzZXMiLCJxdWFsaWJhdCIsImNlcnRpZmljYXRfb3BxaWJpIiwiZW50cmVwcmlzZSIsImV0YWJsaXNzZW1lbnQiXSwic3ViIjoic3RhZ2luZyBkZXZlbG9wbWVudCIsImlhdCI6MTY0MTMwNDcxNCwidmVyc2lvbiI6IjEuMCJ9.6GvMpHhPXmRuY06YMym-kp_67tQhgHxDys3YIH58ws8" }

      it { expect(subject).to be_falsey }
    end

    context "with a valid expiring token" do
      include ActiveSupport::Testing::TimeHelpers

      # expire on Jul 4, 2023 14:58:34
      let(:token) { "eyJhbGciOiJIUzI1NiJ9.eyJ1aWQiOiI2NjRkZWEyMS02YWFlLTQwZmYtYWM0Mi1kZmQ3ZGE4YjQ3NmUiLCJqdGkiOiJhcGktZW50cmVwcmlzZS1zdGFnaW5nIiwicm9sZXMiOlsiY2VydGlmaWNhdF9jbmV0cCIsInByb2J0cCIsImV0YWJsaXNzZW1lbnRzIiwicHJpdmlsZWdlcyIsInVwdGltZSIsImF0dGVzdGF0aW9uc19hZ2VmaXBoIiwiYWN0ZXNfaW5waSIsImJpbGFuc19pbnBpIiwiYWlkZXNfY292aWRfZWZmZWN0aWZzIiwiY2VydGlmaWNhdF9yZ2VfYWRlbWUiLCJhdHRlc3RhdGlvbnNfc29jaWFsZXMiLCJlbnRyZXByaXNlX2FydGlzYW5hbGUiLCJmbnRwX2NhcnRlX3BybyIsImNvbnZlbnRpb25zX2NvbGxlY3RpdmVzIiwiZXh0cmFpdHNfcmNzIiwiZXh0cmFpdF9jb3VydF9pbnBpIiwiY2VydGlmaWNhdF9hZ2VuY2VfYmlvIiwibXNhX2NvdGlzYXRpb25zIiwiZG9jdW1lbnRzX2Fzc29jaWF0aW9uIiwiZW9yaV9kb3VhbmVzIiwiYXNzb2NpYXRpb25zIiwiYmlsYW5zX2VudHJlcHJpc2VfYmRmIiwiZW50cmVwcmlzZXMiLCJxdWFsaWJhdCIsImNlcnRpZmljYXRfb3BxaWJpIiwiZW50cmVwcmlzZSIsImV0YWJsaXNzZW1lbnQiXSwic3ViIjoic3RhZ2luZyBkZXZlbG9wbWVudCIsImlhdCI6MTY0MTMwNDcxNCwidmVyc2lvbiI6IjEuMCIsImV4cCI6MTY4ODQ3NTUxNH0.xID66pIlMnBR5_6nG-GidFBzK4Tuuy5ZsWfkMEVB_Ek" }

      it "must be false when token has not expired yet" do
        travel_to Time.zone.local(2021) do
          expect(subject).to be_falsey
        end
      end

      it "must be true when token has expired" do
        travel_to Time.zone.local(2025) do
          expect(subject).to be_truthy
        end
      end
    end
  end
end
