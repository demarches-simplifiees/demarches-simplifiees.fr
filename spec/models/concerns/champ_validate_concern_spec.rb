# frozen_string_literal: true

RSpec.describe ChampValidateConcern do
  include Logic

  let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:type_de_champ) { dossier.revision.types_de_champ_public.first }
  let(:public_id) { type_de_champ.public_id(nil) }
  let(:types_de_champ_public) { [{ type: :email }] }

  def update_champ(value)
    dossier.public_champ_for_update(public_id, updated_by: 'test').update(value:)
  end

  context 'when in revision' do
    context 'valid' do
      before {
        update_champ('test@test.com')
        dossier.validate(:champs_public_value)
      }
      it {
        expect(dossier.champs).not_to be_empty
        expect(dossier.errors).to be_empty
      }
    end

    context 'invalid' do
      before {
        update_champ('test')
        dossier.validate(:champs_public_value)
      }
      it {
        expect(dossier.champs).not_to be_empty
        expect(dossier.errors).not_to be_empty
      }
    end
  end

  context 'when not in revision' do
    context 'do not validate champs not on current revision' do
      before {
        update_champ('test')
        dossier.revision.revision_types_de_champ.delete_all
        dossier.reload
        dossier.validate(:champs_public_value)
      }
      it {
        expect(dossier.revision.revision_types_de_champ).to be_empty
        expect(dossier.champs).not_to be_empty
        expect(dossier.errors).to be_empty
      }
    end

    context 'attachments' do
      let(:types_de_champ_public) { [{ type: :piece_justificative }, { type: :titre_identite }] }

      before {
        dossier.revision.revision_types_de_champ.delete_all
        dossier.reload
        dossier.validate(:champs_public_value)
      }
      it {
        expect(dossier.revision.revision_types_de_champ).to be_empty
        expect(dossier.champs).not_to be_empty
        expect(dossier.errors).to be_empty
      }
    end

    context 'drop_down_list' do
      let(:types_de_champ_public) { [{ type: :drop_down_list }] }

      before {
        dossier.revision.revision_types_de_champ.delete_all
        dossier.reload
        dossier.validate(:champs_public_value)
      }
      it {
        expect(dossier.revision.revision_types_de_champ).to be_empty
        expect(dossier.champs).not_to be_empty
        expect(dossier.errors).to be_empty
      }
    end
  end

  context 'when type changed' do
    context 'do not validate with old champ type' do
      before {
        update_champ('test')
        type_de_champ.update(type_champ: :text)
        dossier.reload
        dossier.validate(:champs_public_value)
      }
      it {
        expect(dossier.champs.first.last_write_type_champ).to eq('email')
        expect(type_de_champ.type_champ).to eq('text')
        expect(dossier.champs).not_to be_empty
        expect(dossier.errors).to be_empty
      }
    end
  end

  context 'with a conditional row' do
    let(:types_de_champ_public) do
      [
        {
          type: :repetition,
          condition:,
          children: [
            { type: :email }
          ]
        }
      ]
    end
    let(:type_de_champ_in_repetition) { dossier.revision.children_of(type_de_champ).first }
    let(:row_id) { dossier.repetition_row_ids(type_de_champ).first }
    let(:public_id) { type_de_champ_in_repetition.public_id(row_id) }

    before do
      update_champ('test')
      dossier.validate(:champs_public_value)
    end

    context 'when the row is visible' do
      let(:condition) { ds_eq(constant(true), constant(true)) }

      it do
        expect(dossier.errors).not_to be_empty
      end
    end

    context 'when the row is hidden' do
      let(:condition) { ds_eq(constant(true), constant(false)) }

      it do
        expect(dossier.errors).to be_empty
      end
    end
  end

  context 'when in a row' do
    let(:types_de_champ_public) { [{ type: :repetition, children: [{ type: :email }], mandatory: true }] }
    let(:type_de_champ_in_repetition) { dossier.revision.children_of(type_de_champ).first }
    let(:row_id) { dossier.repetition_row_ids(type_de_champ).first }
    let(:public_id) { type_de_champ_in_repetition.public_id(row_id) }

    context 'valid' do
      before {
        update_champ('test@test.com')
        dossier.validate(:champs_public_value)
      }
      it {
        expect(dossier.champs).not_to be_empty
        expect(dossier.errors).to be_empty
      }
    end

    context 'invalid' do
      before {
        update_champ('test')
        dossier.validate(:champs_public_value)
      }
      it {
        expect(dossier.champs).not_to be_empty
        expect(dossier.errors).not_to be_empty
      }
    end

    context 'do not validate when in discarded row' do
      before {
        update_champ('test')
        dossier.repetition_remove_row(type_de_champ, row_id, updated_by: 'test')
        dossier.reload
        dossier.validate(:champs_public_value)
      }
      it {
        expect(dossier.champs).not_to be_empty
        expect(dossier.errors).to be_empty
      }
    end
  end
end
