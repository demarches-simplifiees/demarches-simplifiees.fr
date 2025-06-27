# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TypesDeChamp::LibelleValidator do
  let(:procedure) { create(:procedure, types_de_champ_public: types) }
  let(:type_de_champ) { procedure.active_revision.types_de_champ_public.first }

  subject { procedure.validate(:types_de_champ_public_editor) }

  context 'with a text type de champ' do
    let(:types) { [type: :text] }

    context 'when libelle is filled' do
      it 'does not add errors to the procedure' do
        expect { subject }.not_to change { procedure.errors.count }
      end
    end

    context 'when libelle is empty' do
      before { type_de_champ.update(libelle: '') }

      it 'does add errors to the procedure' do
        expect { subject }.to change { procedure.errors.count }
      end
    end

    context 'when libelle is nil' do
      before { type_de_champ.update(libelle: nil) }

      it 'does add errors to the procedure' do
        expect { subject }.to change { procedure.errors.count }
      end
    end
  end

  context 'with linked drop down list type de champ' do
    let(:types) { [type: :linked_drop_down_list] }
    context 'when libelle is filled' do
      it 'does not add errors to the procedure' do
        expect { subject }.not_to change { procedure.errors.count }
      end
    end

    context 'when libelle is empty' do
      before { type_de_champ.update(libelle: '') }

      it 'does add errors to the procedure' do
        expect { subject }.to change { procedure.errors.count }
      end
    end

    context 'when libelle is nil' do
      before { type_de_champ.update(libelle: nil) }

      it 'does add errors to the procedure' do
        expect { subject }.to change { procedure.errors.count }
      end
    end
  end
end
