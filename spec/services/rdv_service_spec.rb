# frozen_string_literal: true

describe RdvService do
  let(:instructeur) { create(:instructeur) }
  let(:rdv_connection) { create(:rdv_connection, instructeur:) }
  let(:rdv_service) { described_class.new(rdv_connection:) }

  describe '#create_rdv_plan' do
    let(:rdv_plan_result) {
      {
        "rdv_plan":
        {
          "id": 10,
          "created_at": "2025-01-23 15:15:20 +0100",
          "rdv": nil,
          "updated_at": "2025-01-23 15:15:20 +0100",
          "url": "https://demo.rdv.anct.gouv.fr/agents/rdv_plans/10",
          "user_id": 6425
        }
      }
    }

    before do
      stub_request(:post, described_class.create_rdv_plan_url)
        .with(body: {
          user: {
            first_name:,
            last_name:,
            email:
          },
          return_url:,
          dossier_url:
        })
        .to_return(body: rdv_plan_result.to_json)
    end

    subject { rdv_service.create_rdv_plan(dossier:, first_name:, last_name:, email:, dossier_url:, return_url:) }

    context 'when all parameters are valid' do
      let(:dossier) { create(:dossier, :en_instruction) }
      let(:first_name) { "Jean" }
      let(:last_name) { "Michel" }
      let(:email) { "jean.michel@example.fr" }
      let(:dossier_url) { "http://localhost:3000/dossiers/#{dossier.id}" }
      let(:return_url) { "http://localhost:3000/dossiers/#{dossier.id}" }

      it 'creates a new rdv' do
        expect { subject }.to change(Rdv, :count).by(1)

        expect(Rdv.last).to have_attributes(
          dossier_id: dossier.id,
          rdv_plan_external_id: rdv_plan_result[:rdv_plan][:id].to_s
        )
      end

      context 'when token is expired' do
        let(:new_token) do
          instance_double(OAuth2::AccessToken,
            token: 'new_access_token',
            refresh_token: 'new_refresh_token',
            expires_at: 1.hour.from_now.to_i)
        end

        before do
          rdv_connection.update!(expires_at: 1.day.ago)

          # Stub the OAuth2 client and token creation
          allow(OAuth2::Client).to receive(:new).and_return(
            instance_double(OAuth2::Client)
          )

          allow(OAuth2::AccessToken).to receive(:new).and_return(
            instance_double(OAuth2::AccessToken, refresh!: new_token)
          )
        end

        it 'refreshes the token' do
          expect { subject }.to change(rdv_connection, :access_token)
            .to('new_access_token')
            .and change(rdv_connection, :refresh_token)
            .to('new_refresh_token')
        end
      end
    end
  end

  describe '#update_pending_rdv_plan!' do
    let(:dossier) { create(:dossier, :en_instruction) }
    let!(:pending_rdv) { create(:rdv, dossier: dossier, rdv_plan_external_id: "10", rdv_external_id: nil, instructeur:) }
    let(:rdv_plan_result) {
      {
        "rdv_plan": {
          "id": 10,
          "created_at": "2025-01-23 15:15:20 +0100",
          "rdv": {
            "id": 10093,
            "status": "unknown",
            "starts_at": "2025-02-11 10:30:00 +0100",
            "location_type": "phone"
          },
          "updated_at": "2025-01-23 15:15:20 +0100",
          "url": "https://demo.rdv.anct.gouv.fr/agents/rdv_plans/10",
          "user_id": 6425
        }
      }
    }

    before do
      stub_request(:get, described_class.update_pending_rdv_plan_url(pending_rdv.rdv_plan_external_id))
        .to_return(body: rdv_plan_result.to_json)
    end

    subject { rdv_service.update_pending_rdv_plan!(dossier: dossier) }

    context 'when there is a pending rdv plan' do
      it 'updates the rdv with external details' do
        expect { subject }.to change { pending_rdv.reload.rdv_external_id }.from(nil).to("10093")

        expect(pending_rdv.reload).to have_attributes(
          starts_at: Time.zone.parse("2025-02-11 10:30:00 +0100"),
          location_type: "phone"
        )
      end
    end
  end

  describe "#list_rdvs" do
    let(:rdv_ids) { [10093] }
    let(:rdv) {
      {
        "id" => 10093,
        "url_for_agents" => "https://rdv.anct.gouv.fr/rdvs/10093",
        "starts_at" => "2025-06-04 11:30:00 +0200",
        "motif" => { "location_type" => "phone" },
        "agents" => [{ "id" => 1957, "email" => "tom@plop.fr", "first_name" => "Tom", "last_name" => "Plop" }]
      }
    }

    before do
      stub_request(:get, described_class.list_rdvs_url(rdv_ids))
        .to_return(body: {
          rdvs: [rdv]
        }.to_json)
    end

    subject { rdv_service.list_rdvs(rdv_ids) }

    it "returns the rdvs" do
      expect(subject).to eq([rdv])
    end

    context "when the array is empty" do
      let(:rdv_ids) { [] }

      it "returns an empty array" do
        expect(subject).to eq([])
      end
    end

    context "when the request fails" do
      before do
        stub_request(:get, described_class.list_rdvs_url(rdv_ids))
          .to_return(status: 500)
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe '.rdv_sp_host_url' do
    it 'returns the RDV service public URL from environment' do
      expect(described_class.rdv_sp_host_url).to eq(ENV["RDV_SERVICE_PUBLIC_URL"])
    end
  end

  describe '.rdv_sp_org_config_url' do
    it 'returns the organization configuration URL' do
      expected_url = "#{ENV['RDV_SERVICE_PUBLIC_URL']}/admin/organisations/configuration"
      expect(described_class.rdv_sp_org_config_url).to eq(expected_url)
    end
  end

  describe '.rdv_sp_agenda_url' do
    it 'returns the agenda URL' do
      expected_url = "#{ENV['RDV_SERVICE_PUBLIC_URL']}/agents/agenda"
      expect(described_class.rdv_sp_agenda_url).to eq(expected_url)
    end
  end

  describe '.create_rdv_plan_url' do
    it 'returns the create RDV plan URL' do
      expected_url = "#{ENV['RDV_SERVICE_PUBLIC_URL']}/api/v1/rdv_plans"
      expect(described_class.create_rdv_plan_url).to eq(expected_url)
    end
  end

  describe '.update_pending_rdv_plan_url' do
    it 'returns the update pending RDV plan URL' do
      rdv_plan_external_id = "123"
      expected_url = "#{ENV['RDV_SERVICE_PUBLIC_URL']}/api/v1/rdv_plans/#{rdv_plan_external_id}"
      expect(described_class.update_pending_rdv_plan_url(rdv_plan_external_id)).to eq(expected_url)
    end
  end

  describe '.rdv_sp_rdv_user_url' do
    it 'returns the RDV user URL' do
      rdv_id = "456"
      expected_url = "#{ENV['RDV_SERVICE_PUBLIC_URL']}/users/rdvs/#{rdv_id}"
      expect(described_class.rdv_sp_rdv_user_url(rdv_id)).to eq(expected_url)
    end
  end

  describe '.rdv_sp_rdv_agent_url' do
    it 'returns the RDV agent URL' do
      rdv_id = "789"
      expected_url = "#{ENV['RDV_SERVICE_PUBLIC_URL']}/agents/rdvs/#{rdv_id}"
      expect(described_class.rdv_sp_rdv_agent_url(rdv_id)).to eq(expected_url)
    end
  end

  describe '.list_rdvs_url' do
    it 'returns the list RDVs URL with query parameters' do
      rdv_ids = ["123", "456"]
      expected_url = "#{ENV['RDV_SERVICE_PUBLIC_URL']}/api/v1/rdvs?id[]=123&id[]=456"
      expect(described_class.list_rdvs_url(rdv_ids)).to eq(expected_url)
    end
  end
end
