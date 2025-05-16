# frozen_string_literal: true

RSpec.describe Types::DemarcheType, type: :graphql do
  let(:admin) { administrateurs(:default_admin) }
  let(:query) { '' }
  let(:context) { { procedure_ids: admin.procedure_ids } }
  let(:variables) { {} }

  subject { API::V2::Schema.execute(query, variables: variables, context: context) }

  let(:data) { subject['data'].deep_symbolize_keys }
  let(:errors) { subject['errors'].deep_symbolize_keys }

  describe 'context should correctly preserve demarche authorization state' do
    let(:query) { DEMARCHE_QUERY }
    let(:procedure) { create(:procedure, administrateurs: [admin]) }

    let(:other_admin_procedure) { create(:procedure) }
    let(:variables) { { number: procedure.id } }

    it do
      result = API::V2::Schema.execute(query, variables: variables, context: context)
      graphql_context = result.context

      expect(graphql_context.authorized_demarche?(procedure)).to be_truthy
      expect(graphql_context.authorized_demarche?(other_admin_procedure)).to be_falsey
    end
  end

  describe 'demarche with clone' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no }], administrateurs: [admin]) }
    let(:procedure_clone) { procedure.clone(admin:) }
    let(:query) { DEMARCHE_WITH_CHAMP_DESCRIPTORS_QUERY }
    let(:variables) { { number: procedure_clone.id } }
    let(:champ_descriptor_id) { procedure.draft_revision.types_de_champ_public.first.to_typed_id }

    it {
      expect(data[:demarche][:champDescriptors]).to eq(data[:demarche][:draftRevision][:champDescriptors])
      expect(data[:demarche][:champDescriptors][0][:id]).to eq(champ_descriptor_id)
      expect(data[:demarche][:draftRevision][:champDescriptors][0][:id]).to eq(champ_descriptor_id)
      expect(procedure.draft_revision.types_de_champ_public.first.id).not_to eq(procedure_clone.draft_revision.types_de_champ_public.first.id)
      expect(procedure.draft_revision.types_de_champ_public.first.stable_id).to eq(procedure_clone.draft_revision.types_de_champ_public.first.stable_id)
    }
  end
  DEMARCHE_QUERY = <<-GRAPHQL
  query($number: Int!) {
    demarche(number: $number) {
      number
    }
  }
  GRAPHQL

  DEMARCHE_WITH_CHAMP_DESCRIPTORS_QUERY = <<-GRAPHQL
  query($number: Int!) {
    demarche(number: $number) {
      number
      champDescriptors {
        id
        label
      }
      draftRevision {
        champDescriptors {
          id
          label
        }
      }
    }
  }
  GRAPHQL
end
