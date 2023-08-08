describe Procedure::RoutingRulesComponent, type: :component do
  include Logic

  describe 'render' do
    let(:procedure) do
      create(:procedure, types_de_champ_public: [{ type: :integer_number, libelle: 'Age' }])
        .tap { _1.groupe_instructeurs.create(label: 'groupe 2') }
    end

    subject do
      render_inline(described_class.new(revision: procedure.active_revision,
        groupe_instructeurs: procedure.groupe_instructeurs))
    end

    context 'when there are no types de champ that can be routed' do
      before do
        procedure.publish_revision!
        procedure.reload
        subject
      end
      it { expect(page).to have_text('Ajoutez ce champ dans la page') }
    end

    context 'when there are types de champ that can be routed' do
      before do
        procedure.draft_revision.add_type_de_champ({
          type_champ: :drop_down_list,
          libelle: 'Votre ville',
          drop_down_list_value: "Paris\nLyon\nMarseille"
        })
        procedure.publish_revision!
        procedure.reload
        subject
      end
      it { expect(page).to have_text('Router vers') }
    end
  end
end
