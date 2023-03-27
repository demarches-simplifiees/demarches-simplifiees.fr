describe Procedure::RoutingRulesComponent, type: :component do
  include Logic

  describe 'render' do
    let(:procedure) do
      create(:procedure, types_de_champ_public: [{ type: :integer_number, libelle: 'Age' }])
        .tap {_1.groupe_instructeurs.create(label: 'groupe 2')}
    end

    before { render_inline(described_class.new(procedure:)) }

    context 'when there are no types de champ that can be routed' do
      it { expect(page).to have_text('NONONO') }
    end
  end
end
