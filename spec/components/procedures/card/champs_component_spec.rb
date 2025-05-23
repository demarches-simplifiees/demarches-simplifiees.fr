# frozen_string_literal: true

describe Procedure::Card::ChampsComponent, type: :component do
  describe 'render' do
    let(:procedure) { create(:procedure, id: 1, types_de_champ_private:, types_de_champ_public:) }
    let(:types_de_champ_private) { [] }
    let(:types_de_champ_public) { [] }
    before { procedure.validate(:publication) }
    subject { render_inline(described_class.new(procedure: procedure)) }

    context 'when no errors' do
      it 'does not render' do
        expect(subject).to have_selector('.fr-badge--warning', text: 'À faire')
      end
    end

    context 'when errors on types_de_champs_public' do
      let(:types_de_champ_public) { [{ type: :repetition, children: [] }] }
      it 'does not render' do
        expect(subject).to have_selector('.fr-badge--error', text: 'À modifier')
      end
    end

    context 'when errors on types_de_champs_private' do
      let(:types_de_champ_private) { [{ type: :repetition, children: [] }] }

      it 'render the template' do
        expect(subject).to have_selector('.fr-badge--warning', text: 'À faire')
      end
    end
  end
end
