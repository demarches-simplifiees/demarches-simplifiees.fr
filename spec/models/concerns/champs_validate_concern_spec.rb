# frozen_string_literal: true

RSpec.describe ChampsValidateConcern do
  let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
  let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:type_de_champ) { dossier.revision.types_de_champ_public.first }

  let(:types_de_champ_public) { [{ type: :email }] }

  def update_champ(value)
    dossier.update_champs_attributes({
      type_de_champ.stable_id.to_s => { value: }
    }, :public, updated_by: 'test')
    dossier.save
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
end
