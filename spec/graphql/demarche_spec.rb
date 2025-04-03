# frozen_string_literal: true

RSpec.describe Types::DemarcheType, type: :graphql do
  let(:admin) { administrateurs(:default_admin) }
  let(:admin_2) { create(:administrateur) }
  let(:query) { '' }
  let(:context) { { administrateur_id: admin.id, procedure_ids: admin.procedure_ids, write_access: true } }
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
    let(:procedure_clone) { procedure.clone(admin, false) }
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

  describe 'add administrateur' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no }], administrateurs: [admin]) }
    let(:query) { ADD_ADMINISTRATEUR_DEMARCHE_QUERY }
    let(:variables) { { demarcheNumber: procedure.id, email: admin_2.email } }

    it do
      expect(procedure.administrateurs.count).to eq(1)
      expect(procedure.administrateurs[0]).to eq(admin)
      expect(data[:demarcheAjouterAdministrateur][:errors]).to eq(nil)
      procedure.reload
      expect(procedure.administrateurs.count).to eq(2)
      expect(procedure.administrateurs[0]).to eq(admin)
      expect(procedure.administrateurs[1]).to eq(admin_2)
    end
  end

  describe 'add administrateur missing right' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no }], administrateurs: [admin]) }
    let(:query) { ADD_ADMINISTRATEUR_DEMARCHE_QUERY }
    let(:variables) { { demarcheNumber: procedure.id, email: admin_2.email } }
    let(:context) { { administrateur_id: admin_2.id, procedure_ids: admin_2.procedure_ids, write_access: true } }

    it do
      expect(procedure.administrateurs.count).to eq(1)
      expect(procedure.administrateurs[0]).to eq(admin)
      expect(data[:demarcheAjouterAdministrateur][:errors]).to eq([{ message: "Vous n'avez pas le droit d'ajouter un administrateur sur la démarche" }])
      expect(procedure.administrateurs.count).to eq(1)
      expect(procedure.administrateurs[0]).to eq(admin)
    end
  end

  describe 'remove administrateur' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no }], administrateurs: [admin]) }

    let(:query) { REMOVE_ADMINISTRATEUR_DEMARCHE_QUERY }
    let(:variables) { { demarcheNumber: procedure.id, email: admin_2.email } }

    before do
      procedure.administrateurs_procedures.create(administrateur: admin_2)
    end

    it do
      expect(procedure.administrateurs.count).to eq(2)
      expect(procedure.administrateurs[0]).to eq(admin)
      expect(procedure.administrateurs[1]).to eq(admin_2)
      expect(data[:demarcheSupprimerAdministrateur][:errors]).to eq(nil)
      procedure.reload
      expect(procedure.administrateurs.count).to eq(1)
      expect(procedure.administrateurs[0]).to eq(admin)
    end
  end

  describe 'remove administrateur missing right' do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no }], administrateurs: [admin]) }
    let(:query) { REMOVE_ADMINISTRATEUR_DEMARCHE_QUERY }
    let(:variables) { { demarcheNumber: procedure.id, email: admin_2.email } }
    let(:context) { { administrateur_id: admin_2.id, procedure_ids: admin_2.procedure_ids, write_access: true } }

    it do
      expect(procedure.administrateurs.count).to eq(1)
      expect(procedure.administrateurs[0]).to eq(admin)
      expect(data[:demarcheSupprimerAdministrateur][:errors]).to eq([{ message: "Vous n'avez pas le droit de retirer un administrateur sur la démarche" }])
      expect(procedure.administrateurs.count).to eq(1)
      expect(procedure.administrateurs[0]).to eq(admin)
    end
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

  ADD_ADMINISTRATEUR_DEMARCHE_QUERY = <<-GRAPHQL
  mutation AjouterAdmin($demarcheNumber: Int!, $email: String!) {
    demarcheAjouterAdministrateur(
      input: {demarche: {number: $demarcheNumber}, administrateurs: [{ email: $email }] }
    ) {
      clientMutationId
      demarche {
        id
      }
      errors {
        message
      }
    }
  }
  GRAPHQL

  REMOVE_ADMINISTRATEUR_DEMARCHE_QUERY = <<-GRAPHQL
  mutation SupprimerAdmin($demarcheNumber: Int!, $email: String!) {
    demarcheSupprimerAdministrateur(
      input: {demarche: {number: $demarcheNumber}, administrateurs: [{ email: $email }] }
    ) {
      clientMutationId
      demarche {
        id
      }
      errors {
        message
      }
    }
  }
  GRAPHQL
end
