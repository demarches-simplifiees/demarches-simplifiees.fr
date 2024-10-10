# frozen_string_literal: true

describe Instructeurs::ColumnFilterComponent, type: :component do
  let(:component) { described_class.new(procedure:, procedure_presentation:, statut:, column:) }

  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure, instructeurs: [instructeur]) }
  let(:procedure_id) { procedure.id }
  let(:procedure_presentation) { nil }
  let(:statut) { nil }
  let(:column) { nil }

  before do
    allow(component).to receive(:current_instructeur).and_return(instructeur)
  end

  describe ".filterable_columns_options" do
    let(:filterable_column) { Column.new(procedure_id:, label: 'email', table: 'user', column: 'email') }
    let(:non_filterable_column) { Column.new(procedure_id:, label: 'depose_since', table: 'self', column: 'depose_since', filterable: false) }
    let(:mocked_columns) { [filterable_column, non_filterable_column] }

    before { allow(procedure).to receive(:columns).and_return(mocked_columns) }

    subject { component.filterable_columns_options }

    it { is_expected.to eq([[filterable_column.label, filterable_column.id]]) }
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
      let(:column) { Column.new(procedure_id:, table: 'type_de_champ', scope: nil, column: drop_down_stable_id) }

      it 'find most recent tdc' do
        is_expected.to eq(['Paris', 'Lyon', 'Marseille'])
      end
    end
  end
end
