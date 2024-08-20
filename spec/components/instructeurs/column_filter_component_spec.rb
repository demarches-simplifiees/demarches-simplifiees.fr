describe Instructeurs::ColumnFilterComponent, type: :component do
  let(:component) { described_class.new(procedure:, procedure_presentation:, statut:, column:) }

  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, instructeurs: [instructeur]) }
  let(:procedure_presentation) { nil }
  let(:statut) { nil }

  before do
    allow(component).to receive(:current_instructeur).and_return(instructeur)
  end

  describe ".filterable_columns_options" do
    context 'filders' do
      let(:column) { nil }
      let(:included_displayable_field) do
        [
          Column.new(label: 'email', table: 'user', column: 'email'),
          Column.new(label: "depose_since", table: "self", column: "depose_since", displayable: false)
        ]
      end

      before { allow(procedure).to receive(:columns).and_return(included_displayable_field) }

      subject { component.filterable_columns_options }

      it { is_expected.to eq([["email", "user/email"], ["depose_since", "self/depose_since"]]) }
    end
  end

  describe '.options_for_select_of_column' do
    subject { component.options_for_select_of_column }

    context "column is groupe_instructeur" do
      let(:column) { double("Column", scope: nil, table: 'groupe_instructeur') }
      let!(:gi_2) { instructeur.groupe_instructeurs.create(label: 'gi2', procedure:) }
      let!(:gi_3) { instructeur.groupe_instructeurs.create(label: 'gi3', procedure: create(:procedure)) }

      it { is_expected.to eq([['défaut', procedure.defaut_groupe_instructeur.id], ['gi2', gi_2.id]]) }
    end

    context 'when column is dropdown' do
      let(:types_de_champ_public) { [{ type: :drop_down_list, libelle: 'Votre ville', options: ['Paris', 'Lyon', 'Marseille'] }] }
      let(:procedure) { create(:procedure, :published, types_de_champ_public:) }
      let(:drop_down_stable_id) { procedure.active_revision.types_de_champ.first.stable_id }
      let(:column) { Column.new(table: 'type_de_champ', scope: nil, column: drop_down_stable_id) }

      it 'find most recent tdc' do
        is_expected.to eq(['Paris', 'Lyon', 'Marseille'])
      end
    end
  end
end
