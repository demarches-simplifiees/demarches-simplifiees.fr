# frozen_string_literal: true

describe Procedure::Card::AnnotationsComponent, type: :component do
  describe 'render' do
    let(:procedure) { create(:procedure, id: 1, types_de_champ_private:, types_de_champ_public:) }
    let(:types_de_champ_private) { [] }
    let(:types_de_champ_public) { [] }
    before { procedure.validate(:publication) }
    subject { render_inline(described_class.new(procedure: procedure)) }

    context 'when no errors' do
      it 'does not render' do
        expect(subject).to have_selector('.fr-badge--info', text: 'À configurer')
      end
    end

    context 'when errors on types_de_champs_public' do
      let(:types_de_champ_public) { [{ type: :drop_down_list, options: [] }] }
      it 'does not render' do
        expect(subject).to have_selector('.fr-badge--info', text: 'À configurer')
      end
    end

    context 'when errors on types_de_champs_private' do
      let(:types_de_champ_private) { [{ type: :drop_down_list, options: [] }] }

      it 'render the template' do
        expect(subject).to have_selector('.fr-badge--error', text: 'À modifier')
      end
    end
  end
end
