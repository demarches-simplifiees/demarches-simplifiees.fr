describe APIEntrepriseToken, type: :model do
  let(:api_entreprise_token) { APIEntrepriseToken.new(token) }

  describe "#token (old version)" do
    subject { api_entreprise_token.token }

    context "without token" do
      let(:token) { nil }

      it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
    end

    context "with a blank token" do
      let(:token) { "" }

      it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
    end

    context "with an invalid token" do
      let(:token) { "NOT-A-VALID-TOKEN" }

      it { expect(subject).to equal(token) }
    end

    context "with a valid token" do
      let(:token) { "eyJhbGciOiJIUzI1NiJ9.eyJ1aWQiOiI2NjRkZWEyMS02YWFlLTQwZmYtYWM0Mi1kZmQ3ZGE4YjQ3NmUiLCJqdGkiOiJhcGktZW50cmVwcmlzZS1zdGFnaW5nIiwicm9sZXMiOlsiY2VydGlmaWNhdF9jbmV0cCIsInByb2J0cCIsImV0YWJsaXNzZW1lbnRzIiwicHJpdmlsZWdlcyIsInVwdGltZSIsImF0dGVzdGF0aW9uc19hZ2VmaXBoIiwiYWN0ZXNfaW5waSIsImJpbGFuc19pbnBpIiwiYWlkZXNfY292aWRfZWZmZWN0aWZzIiwiY2VydGlmaWNhdF9yZ2VfYWRlbWUiLCJhdHRlc3RhdGlvbnNfc29jaWFsZXMiLCJlbnRyZXByaXNlX2FydGlzYW5hbGUiLCJmbnRwX2NhcnRlX3BybyIsImNvbnZlbnRpb25zX2NvbGxlY3RpdmVzIiwiZXh0cmFpdHNfcmNzIiwiZXh0cmFpdF9jb3VydF9pbnBpIiwiY2VydGlmaWNhdF9hZ2VuY2VfYmlvIiwibXNhX2NvdGlzYXRpb25zIiwiZG9jdW1lbnRzX2Fzc29jaWF0aW9uIiwiZW9yaV9kb3VhbmVzIiwiYXNzb2NpYXRpb25zIiwiYmlsYW5zX2VudHJlcHJpc2VfYmRmIiwiZW50cmVwcmlzZXMiLCJxdWFsaWJhdCIsImNlcnRpZmljYXRfb3BxaWJpIiwiZW50cmVwcmlzZSIsImV0YWJsaXNzZW1lbnQiXSwic3ViIjoic3RhZ2luZyBkZXZlbG9wbWVudCIsImlhdCI6MTY0MTMwNDcxNCwidmVyc2lvbiI6IjEuMCIsImV4cCI6MTY4ODQ3NTUxNH0.xID66pIlMnBR5_6nG-GidFBzK4Tuuy5ZsWfkMEVB_Ek" }

      it { expect(subject).to equal(token) }
    end

    context "roles?" do
      let(:token) { "eyJhbGciOiJIUzI1NiJ9.eyJ1aWQiOiI1MmE1YmZjMi1jMzUwLTQ4ZjQtYjY5Ni05ZWE3NmRiM2VmMjkiLCJqdGkiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDAiLCJzY29wZXMiOlsiY2VydGlmaWNhdF9yZ2VfYWRlbWUiLCJtc2FfY290aXNhdGlvbnMiLCJlbnRyZXByaXNlcyIsImV4dHJhaXRzX3JjcyIsImNlcnRpZmljYXRfb3BxaWJpIiwiYXNzb2NpYXRpb25zIiwiZXRhYmxpc3NlbWVudHMiLCJmbnRwX2NhcnRlX3BybyIsInF1YWxpYmF0IiwiZW50cmVwcmlzZXNfYXJ0aXNhbmFsZXMiLCJjZXJ0aWZpY2F0X2NuZXRwIiwiZW9yaV9kb3VhbmVzIiwicHJvYnRwIiwiYWN0ZXNfaW5waSIsImV4dHJhaXRfY291cnRfaW5waSIsImF0dGVzdGF0aW9uc19zb2NpYWxlcyIsImxpYXNzZV9maXNjYWxlIiwiYXR0ZXN0YXRpb25zX2Zpc2NhbGVzIiwiZXhlcmNpY2VzIiwiY29udmVudGlvbnNfY29sbGVjdGl2ZXMiLCJiaWxhbnNfaW5waSIsImRvY3VtZW50c19hc3NvY2lhdGlvbiIsImNlcnRpZmljYXRfYWdlbmNlX2JpbyIsImJpbGFuc19lbnRyZXByaXNlX2JkZiIsImF0dGVzdGF0aW9uc19hZ2VmaXBoIiwibWVzcmlfaWRlbnRpZmlhbnQiLCJtZXNyaV9pZGVudGl0ZSIsIm1lc3JpX2luc2NyaXB0aW9uX2V0dWRpYW50IiwibWVzcmlfaW5zY3JpcHRpb25fYXV0cmUiLCJtZXNyaV9hZG1pc3Npb24iLCJtZXNyaV9ldGFibGlzc2VtZW50cyIsInBvbGVfZW1wbG9pX2lkZW50aXRlIiwicG9sZV9lbXBsb2lfYWRyZXNzZSIsInBvbGVfZW1wbG9pX2NvbnRhY3QiLCJwb2xlX2VtcGxvaV9pbnNjcmlwdGlvbiIsImNuYWZfcXVvdGllbnRfZmFtaWxpYWwiLCJjbmFmX2FsbG9jYXRhaXJlcyIsImNuYWZfZW5mYW50cyIsImNuYWZfYWRyZXNzZSIsImNub3VzX3N0YXR1dF9ib3Vyc2llciIsInVwdGltZSIsImNub3VzX2VjaGVsb25fYm91cnNlIiwiY25vdXNfZW1haWwiLCJjbm91c19wZXJpb2RlX3ZlcnNlbWVudCIsImNub3VzX3N0YXR1dF9ib3Vyc2UiLCJjbm91c192aWxsZV9ldHVkZXMiLCJjbm91c19pZGVudGl0ZSIsImRnZmlwX2RlY2xhcmFudDFfbm9tIiwiZGdmaXBfZGVjbGFyYW50MV9ub21fbmFpc3NhbmNlIiwiZGdmaXBfZGVjbGFyYW50MV9wcmVub21zIiwiZGdmaXBfZGVjbGFyYW50MV9kYXRlX25haXNzYW5jZSIsImRnZmlwX2RlY2xhcmFudDJfbm9tIiwiZGdmaXBfZGVjbGFyYW50Ml9ub21fbmFpc3NhbmNlIiwiZGdmaXBfZGVjbGFyYW50Ml9wcmVub21zIiwiZGdmaXBfZGVjbGFyYW50Ml9kYXRlX25haXNzYW5jZSIsImRnZmlwX2RhdGVfcmVjb3V2cmVtZW50IiwiZGdmaXBfZGF0ZV9ldGFibGlzc2VtZW50IiwiZGdmaXBfYWRyZXNzZV9maXNjYWxlX3RheGF0aW9uIiwiZGdmaXBfYWRyZXNzZV9maXNjYWxlX2FubmVlIiwiZGdmaXBfbm9tYnJlX3BhcnRzIiwiZGdmaXBfbm9tYnJlX3BlcnNvbm5lc19hX2NoYXJnZSIsImRnZmlwX3NpdHVhdGlvbl9mYW1pbGlhbGUiLCJkZ2ZpcF9yZXZlbnVfYnJ1dF9nbG9iYWwiLCJkZ2ZpcF9yZXZlbnVfaW1wb3NhYmxlIiwiZGdmaXBfaW1wb3RfcmV2ZW51X25ldF9hdmFudF9jb3JyZWN0aW9ucyIsImRnZmlwX21vbnRhbnRfaW1wb3QiLCJkZ2ZpcF9yZXZlbnVfZmlzY2FsX3JlZmVyZW5jZSIsImRnZmlwX2FubmVlX2ltcG90IiwiZGdmaXBfYW5uZWVfcmV2ZW51cyIsImRnZmlwX2VycmV1cl9jb3JyZWN0aWYiLCJkZ2ZpcF9zaXR1YXRpb25fcGFydGllbGxlIl0sInN1YiI6InN0YWdpbmcgZGV2ZWxvcG1lbnQiLCJpYXQiOjE2NjY4NjQwNzQsInZlcnNpb24iOiIxLjAiLCJleHAiOjE5ODI0ODMyNzR9.u2kMWzll3iCTczUOqMQbpS66VfrVzI2lLiyGEPcKAec" }

      it { expect(api_entreprise_token.role?('bilans_entreprise_bdf')).to equal(true) }
    end
  end

  describe "#token (new version)" do
    subject { api_entreprise_token.token }

    context "with a valid token" do
      let(:token) { "eyJhbGciOiJIUzI1NiJ9.eyJ1aWQiOiI1MmE1YmZjMi1jMzUwLTQ4ZjQtYjY5Ni05ZWE3NmRiM2VmMjkiLCJqdGkiOiIwMDAwMDAwMC0wMDAwLTAwMDAtMDAwMC0wMDAwMDAwMDAwMDAiLCJzY29wZXMiOlsiY2VydGlmaWNhdF9yZ2VfYWRlbWUiLCJtc2FfY290aXNhdGlvbnMiLCJlbnRyZXByaXNlcyIsImV4dHJhaXRzX3JjcyIsImNlcnRpZmljYXRfb3BxaWJpIiwiYXNzb2NpYXRpb25zIiwiZXRhYmxpc3NlbWVudHMiLCJmbnRwX2NhcnRlX3BybyIsInF1YWxpYmF0IiwiZW50cmVwcmlzZXNfYXJ0aXNhbmFsZXMiLCJjZXJ0aWZpY2F0X2NuZXRwIiwiZW9yaV9kb3VhbmVzIiwicHJvYnRwIiwiYWN0ZXNfaW5waSIsImV4dHJhaXRfY291cnRfaW5waSIsImF0dGVzdGF0aW9uc19zb2NpYWxlcyIsImxpYXNzZV9maXNjYWxlIiwiYXR0ZXN0YXRpb25zX2Zpc2NhbGVzIiwiZXhlcmNpY2VzIiwiY29udmVudGlvbnNfY29sbGVjdGl2ZXMiLCJiaWxhbnNfaW5waSIsImRvY3VtZW50c19hc3NvY2lhdGlvbiIsImNlcnRpZmljYXRfYWdlbmNlX2JpbyIsImJpbGFuc19lbnRyZXByaXNlX2JkZiIsImF0dGVzdGF0aW9uc19hZ2VmaXBoIiwibWVzcmlfaWRlbnRpZmlhbnQiLCJtZXNyaV9pZGVudGl0ZSIsIm1lc3JpX2luc2NyaXB0aW9uX2V0dWRpYW50IiwibWVzcmlfaW5zY3JpcHRpb25fYXV0cmUiLCJtZXNyaV9hZG1pc3Npb24iLCJtZXNyaV9ldGFibGlzc2VtZW50cyIsInBvbGVfZW1wbG9pX2lkZW50aXRlIiwicG9sZV9lbXBsb2lfYWRyZXNzZSIsInBvbGVfZW1wbG9pX2NvbnRhY3QiLCJwb2xlX2VtcGxvaV9pbnNjcmlwdGlvbiIsImNuYWZfcXVvdGllbnRfZmFtaWxpYWwiLCJjbmFmX2FsbG9jYXRhaXJlcyIsImNuYWZfZW5mYW50cyIsImNuYWZfYWRyZXNzZSIsImNub3VzX3N0YXR1dF9ib3Vyc2llciIsInVwdGltZSIsImNub3VzX2VjaGVsb25fYm91cnNlIiwiY25vdXNfZW1haWwiLCJjbm91c19wZXJpb2RlX3ZlcnNlbWVudCIsImNub3VzX3N0YXR1dF9ib3Vyc2UiLCJjbm91c192aWxsZV9ldHVkZXMiLCJjbm91c19pZGVudGl0ZSIsImRnZmlwX2RlY2xhcmFudDFfbm9tIiwiZGdmaXBfZGVjbGFyYW50MV9ub21fbmFpc3NhbmNlIiwiZGdmaXBfZGVjbGFyYW50MV9wcmVub21zIiwiZGdmaXBfZGVjbGFyYW50MV9kYXRlX25haXNzYW5jZSIsImRnZmlwX2RlY2xhcmFudDJfbm9tIiwiZGdmaXBfZGVjbGFyYW50Ml9ub21fbmFpc3NhbmNlIiwiZGdmaXBfZGVjbGFyYW50Ml9wcmVub21zIiwiZGdmaXBfZGVjbGFyYW50Ml9kYXRlX25haXNzYW5jZSIsImRnZmlwX2RhdGVfcmVjb3V2cmVtZW50IiwiZGdmaXBfZGF0ZV9ldGFibGlzc2VtZW50IiwiZGdmaXBfYWRyZXNzZV9maXNjYWxlX3RheGF0aW9uIiwiZGdmaXBfYWRyZXNzZV9maXNjYWxlX2FubmVlIiwiZGdmaXBfbm9tYnJlX3BhcnRzIiwiZGdmaXBfbm9tYnJlX3BlcnNvbm5lc19hX2NoYXJnZSIsImRnZmlwX3NpdHVhdGlvbl9mYW1pbGlhbGUiLCJkZ2ZpcF9yZXZlbnVfYnJ1dF9nbG9iYWwiLCJkZ2ZpcF9yZXZlbnVfaW1wb3NhYmxlIiwiZGdmaXBfaW1wb3RfcmV2ZW51X25ldF9hdmFudF9jb3JyZWN0aW9ucyIsImRnZmlwX21vbnRhbnRfaW1wb3QiLCJkZ2ZpcF9yZXZlbnVfZmlzY2FsX3JlZmVyZW5jZSIsImRnZmlwX2FubmVlX2ltcG90IiwiZGdmaXBfYW5uZWVfcmV2ZW51cyIsImRnZmlwX2VycmV1cl9jb3JyZWN0aWYiLCJkZ2ZpcF9zaXR1YXRpb25fcGFydGllbGxlIl0sInN1YiI6InN0YWdpbmcgZGV2ZWxvcG1lbnQiLCJpYXQiOjE2NjY4NjQwNzQsInZlcnNpb24iOiIxLjAiLCJleHAiOjE5ODI0ODMyNzR9.u2kMWzll3iCTczUOqMQbpS66VfrVzI2lLiyGEPcKAecx" }

      it { expect(api_entreprise_token.role?('bilans_entreprise_bdf')).to equal(true) }
    end

    context 'roles?' do
      it 'works' do
      end
    end
  end

  describe "#role?" do
    subject { api_entreprise_token.role?(role) }

    context "without token" do
      let(:token) { nil }
      let(:role) { "actes_inpi" }

      it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
    end

    context "with a blank token" do
      let(:token) { "" }
      let(:role) { "actes_inpi" }

      it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
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

      it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
    end

    context "with a blank token" do
      let(:token) { "" }

      it { expect { subject }.to raise_exception(APIEntrepriseToken::TokenError) }
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
