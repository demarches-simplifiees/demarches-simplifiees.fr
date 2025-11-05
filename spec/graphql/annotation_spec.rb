# frozen_string_literal: true

RSpec.describe Mutations::DossierModifierAnnotation, type: :graphql do
  let(:admin) { administrateurs(:default_admin) }
  let(:procedure) { create(:procedure, :published, :for_individual, types_de_champ_private: [{ type: :repetition, children: [{ libelle: 'Nom' }, { type: :integer_number, libelle: 'Age' }, { type: :decimal_number, libelle: 'Montant' }] }, { type: :decimal_number, libelle: 'Montant' }, {}], administrateurs: [admin]) }
  let(:dossiers) { [] }
  let(:instructeur) { create(:instructeur, followed_dossiers: dossiers) }
  let(:champs_private) { dossier.project_champs_private }

  let(:query) { '' }
  let(:context) { { administrateur_id: admin.id, procedure_ids: admin.procedure_ids, write_access: true } }
  let(:variables) { {} }

  subject { API::V2::Schema.execute(query, variables: variables, context: context) }

  let(:data) { subject['data'].deep_symbolize_keys }
  let(:errors) { subject['errors'].deep_symbolize_keys }

  before do
    instructeur.assign_to_procedure(procedure)
  end

  describe 'dossierModifierAnnotationAjouterLigne' do
    let(:dossier) { create(:dossier, :en_construction, :with_populated_annotations, procedure: procedure) }
    let(:dossiers) { [dossier] }

    let(:annotation) { champs_private.find(&:repetition?) }
    let(:query) { DOSSIER_MODIFIER_ANNOTATION_AJOUTER_LIGNE_MUTATION }
    let(:variables) do
      {
        input: {
          dossierId: dossier.to_typed_id,
          annotationId: annotation.to_typed_id,
          instructeurId: instructeur.to_typed_id,
        },
      }
    end

    context 'with invalid champ' do
      let(:annotation) { champs_private.last }

      it 'return error' do
        expect(data).to eq(dossierModifierAnnotationAjouterLigne: {
          annotation: nil,
          errors: [{ message: "L’annotation \"#{annotation.to_typed_id}\" n’existe pas" }],
        })
      end
    end

    it 'add row' do
      expect(annotation.row_ids.size).to eq(2)
      expect(data).to eq(dossierModifierAnnotationAjouterLigne: {
        annotation: {
          id: annotation.to_typed_id,
        },
        errors: nil,
      })
      dossier.reload
      expect(annotation.row_ids.size).to eq(3)
    end
  end

  describe 'dossierModifierAnnotationText' do
    let(:dossier) { create(:dossier, :en_construction, :with_populated_annotations, procedure: procedure) }
    let(:dossiers) { [dossier] }

    let(:annotation) { champs_private.last }
    let(:query) { DOSSIER_MODIFIER_ANNOTATION_TEXT_MUTATION }
    let(:variables) do
      {
        input: {
          dossierId: dossier.to_typed_id,
          annotationId: annotation.to_typed_id,
          instructeurId: instructeur.to_typed_id,
          value: 'Hello world',
        },
      }
    end

    it 'update champ' do
      expect(data).to eq(dossierModifierAnnotationText: {
        annotation: {
          id: annotation.to_typed_id,
        },
        errors: nil,
      })
      expect(annotation.reload.value).to eq('Hello world')
    end

    context 'with invalid champ' do
      let(:annotation) { champs_private.find(&:repetition?) }

      it 'return error' do
        expect(data).to eq(dossierModifierAnnotationText: {
          annotation: nil,
          errors: [{ message: "L’annotation \"#{annotation.to_typed_id}\" n’existe pas" }],
        })
      end
    end

    context 'with rows' do
      let(:annotation) { champs_private.find(&:repetition?).rows.first.first }
      let(:other_annotation) { champs_private.find(&:repetition?).rows.second.first }

      it 'update champ' do
        expect(data).to eq(dossierModifierAnnotationText: {
          annotation: {
            id: annotation.to_typed_id,
          },
          errors: nil,
        })
        expect(annotation.reload.value).to eq('Hello world')
        expect(other_annotation.reload.value).not_to eq('Hello world')
      end
    end
  end

  describe 'dossierModifierAnnotationDecimalNumber' do
    let(:dossier) { create(:dossier, :en_construction, :with_populated_annotations, procedure: procedure) }
    let(:dossiers) { [dossier] }

    let(:annotation) { champs_private.find(&:decimal_number?) }
    let(:query) { DOSSIER_MODIFIER_ANNOTATION_DECIMAL_MUTATION }
    let(:variables) do
      {
        input: {
          dossierId: dossier.to_typed_id,
          annotationId: annotation.to_typed_id,
          instructeurId: instructeur.to_typed_id,
          value: 12.34,
        },
      }
    end

    it 'update champ' do
      expect(data).to eq(dossierModifierAnnotationDecimalNumber: {
        annotation: {
          id: annotation.to_typed_id,
        },
        errors: nil,
      })
      expect(annotation.reload.value).to eq('12.34')
    end

    context 'with invalid champ' do
      let(:annotation) { champs_private.first }

      it 'return error' do
        expect(data).to eq(dossierModifierAnnotationDecimalNumber: {
          annotation: nil,
          errors: [{ message: "L’annotation \"#{annotation.to_typed_id}\" n’existe pas" }],
        })
      end
    end

    context 'with rows' do
      let(:annotation) { champs_private.find(&:repetition?).rows.first.find(&:decimal_number?) }
      let(:other_annotation) { champs_private.find(&:repetition?).rows.second.find(&:decimal_number?) }

      it 'update champ' do
        expect(data).to eq(dossierModifierAnnotationDecimalNumber: {
          annotation: {
            id: annotation.to_typed_id,
          },
          errors: nil,
        })
        expect(annotation.reload.value).to eq('12.34')
        expect(other_annotation.reload.value).not_to eq('12.34')
      end
    end
  end

  DOSSIER_MODIFIER_ANNOTATION_AJOUTER_LIGNE_MUTATION = <<-GRAPHQL
  mutation($input: DossierModifierAnnotationAjouterLigneInput!) {
    dossierModifierAnnotationAjouterLigne(input: $input) {
      annotation { id }
      errors { message }
    }
  }
  GRAPHQL

  DOSSIER_MODIFIER_ANNOTATION_TEXT_MUTATION = <<-GRAPHQL
  mutation($input: DossierModifierAnnotationTextInput!) {
    dossierModifierAnnotationText(input: $input) {
      annotation { id }
      errors { message }
    }
  }
  GRAPHQL

  DOSSIER_MODIFIER_ANNOTATION_DECIMAL_MUTATION = <<-GRAPHQL
  mutation($input: DossierModifierAnnotationDecimalNumberInput!) {
    dossierModifierAnnotationDecimalNumber(input: $input) {
      annotation { id }
      errors { message }
    }
  }
  GRAPHQL
end
