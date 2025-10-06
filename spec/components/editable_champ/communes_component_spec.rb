# frozen_string_literal: true

describe EditableChamp::CommunesComponent, type: :component do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :communes }]) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:tdc) { procedure.active_revision.types_de_champ.first }
  let(:champs) { dossier.champs }
  let(:champ) { champs.first }

  describe 'aria-describedby' do
    let(:react_component) { page.find('react-component') }
    let(:react_props) { JSON.parse(react_component['props']) }

    subject do
      render_inline(EditableChamp::EditableChampComponent.new(champs:))
      react_props['aria-describedby']&.split
    end

    context 'when the champ has a description' do
      it { is_expected.to eq([champ.describedby_id]) }

      context 'and the champ has an error' do
        before { champ.errors.add(:value, 'error') }

        it { is_expected.to eq([champ.describedby_id, champ.error_id]) }
      end
    end

    context 'when the champ has no description' do
      before { tdc.update(description: nil) }

      it { is_expected.to be_nil }

      context 'and the champ has an error' do
        before { champ.errors.add(:value, 'error') }

        it { is_expected.to eq([champ.error_id]) }
      end
    end
  end
end
