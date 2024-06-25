describe Procedure::Card::IneligibiliteDossierComponent, type: :component do
  describe 'render' do
    subject do
      render_inline(described_class.new(procedure: procedure))
    end

    context 'when none of types_de_champ_public supports conditional' do
      let(:procedure) { create(:procedure, types_de_champ_public: []) }

      it 'render missing setup' do
        subject
        expect(page).to have_text('Champs manquant')
      end
    end

    context 'when at least one of types_de_champ_public support conditional' do
      let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :yes_no }]) }

      it 'render the template' do
        subject
        expect(page).to have_text('À configurer')
      end
    end
  end
end
