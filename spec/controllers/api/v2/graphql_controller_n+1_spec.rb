# frozen_string_literal: true

describe API::V2::GraphqlController do
  let(:admin) { administrateurs(:default_admin) }
  let(:generated_token) { APIToken.generate(admin) }
  let(:token) { generated_token.second }
  let(:procedure) { create(:procedure, :published, :for_individual, :with_service, administrateurs: [admin], types_de_champ_public:) }
  let(:types_de_champ_public) { [{}, { type: :piece_justificative }, { type: :siret }, { type: :repetition, mandatory: true, children: [{}, { type: :piece_justificative }, { type: :siret }] }] }
  let(:authorization_header) { ActionController::HttpAuthentication::Token.encode_credentials(token) }

  let(:query_id) { 'ds-query-v2' }
  let(:variables) { {} }
  let(:operation_name) { nil }
  let(:body) { JSON.parse(subject.body, symbolize_names: true) }
  let(:gql_data) { body[:data] }
  let(:gql_errors) { body[:errors] }

  let(:dossiers_count) { dossiers_per_state * 3 }

  subject { post :execute, params: { queryId: query_id, variables: variables, operationName: operation_name }.compact, as: :json }

  before do
    request.env['HTTP_AUTHORIZATION'] = authorization_header
  end

  MAX_QUERY_COUNT = 70

  describe 'demarche.dossiers' do
    let(:operation_name) { 'getDemarche' }
    let(:variables) { { demarcheNumber: procedure.id, includeDossiers: true, includeTraitements: true, includeRevision: true, includeRevisions: true } }
    let(:dossier) { create(:dossier, :en_construction, :with_individual, :with_populated_champs, procedure:) }
    let(:dossiers_en_instruction) { create_list(:dossier, dossiers_per_state, :en_instruction, :with_individual, :with_populated_champs, procedure:) }
    let(:dossiers_accepte) { create_list(:dossier, dossiers_per_state, :accepte, :with_individual, :with_populated_champs, procedure:) }
    let(:dossiers_refuse) { create_list(:dossier, dossiers_per_state, :refuse, :with_individual, :with_populated_champs, procedure:) }

    it "should not have n+1 on one dossier" do
      query_count = 0

      dossier
      # Execute the query first time to ensure shared queries are never counted in the query counter
      post :execute, params: { queryId: query_id, variables: variables, operationName: operation_name }.compact, as: :json
      ActiveSupport::Notifications.subscribed(lambda { |*_args| query_count += 1 }, "sql.active_record") { subject }

      expect(gql_errors).to be_nil
      expect(gql_data[:demarche][:dossiers][:nodes].count).to eq(1)
      expect(query_count).to be <= MAX_QUERY_COUNT
    end

    context "with 1 dossier per state" do
      let(:dossiers_per_state) { 1 }

      it "should not have n+1" do
        query_count = 0

        dossier
        dossiers_en_instruction
        dossiers_accepte
        dossiers_refuse
        ActiveSupport::Notifications.subscribed(lambda { |*_args| query_count += 1 }, "sql.active_record") { subject }

        expect(gql_errors).to be_nil
        expect(gql_data[:demarche][:dossiers][:nodes].count).to eq(dossiers_count + 1)
        expect(query_count).to be <= MAX_QUERY_COUNT
      end
    end

    context "with 3 dossiers per state" do
      let(:dossiers_per_state) { 3 }

      it "should not have n+1", :slow do
        query_count = 0

        dossier
        dossiers_en_instruction
        dossiers_accepte
        dossiers_refuse
        ActiveSupport::Notifications.subscribed(lambda { |*_args| query_count += 1 }, "sql.active_record") { subject }

        expect(gql_errors).to be_nil
        expect(gql_data[:demarche][:dossiers][:nodes].count).to eq(dossiers_count + 1)
        expect(query_count).to be <= MAX_QUERY_COUNT
      end
    end
  end
end
