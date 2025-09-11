# frozen_string_literal: true

describe Instructeurs::ColumnFilterComponent, type: :component do
  let(:component) { described_class.new(procedure_presentation:, statut:, instructeur_procedure:) }

  let(:instructeur) { create(:instructeur) }
  let(:procedure) { create(:procedure) }
  let(:instructeur_procedure) { create(:instructeurs_procedure, instructeur:, procedure:) }
  let(:procedure_id) { procedure.id }
  let(:procedure_presentation) do
    groupe_instructeur = procedure.defaut_groupe_instructeur
    assign_to = create(:assign_to, instructeur:, groupe_instructeur:)
    assign_to.procedure_presentation_or_default_and_errors.first
  end

  let(:statut) { nil }

  before do
    allow(component).to receive(:current_instructeur).and_return(instructeur)
  end

  describe ".filterable_columns_options" do
    let(:filterable_column) { Column.new(procedure_id:, label: 'email', table: 'user', column: 'email') }
    let(:non_filterable_column) { Column.new(procedure_id:, label: 'depose_since', table: 'self', column: 'depose_since', filterable: false) }
    let(:mocked_columns) { [filterable_column, non_filterable_column] }

    before { allow_any_instance_of(Procedure).to receive(:columns).and_return(mocked_columns) }

    subject { component.filterable_columns_options }

    it { is_expected.to eq([[filterable_column.label, filterable_column.id]]) }
  end
end
