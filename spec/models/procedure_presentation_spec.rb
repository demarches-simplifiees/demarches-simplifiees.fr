# frozen_string_literal: true

describe ProcedurePresentation do
  include ActiveSupport::Testing::TimeHelpers

  let(:procedure) { create(:procedure, :published) }
  let(:procedure_id) { procedure.id }
  let(:instructeur) { create(:instructeur) }
  let(:assign_to) { create(:assign_to, procedure:, instructeur:) }

  describe 'validation' do
    it { expect(build(:procedure_presentation)).to be_valid }

    context 'of displayed columns' do
      it do
        pp = build(:procedure_presentation, displayed_columns: [{ table: "user", column: "reset_password_token", procedure_id: }])
        expect { pp.displayed_columns }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'of filters' do
      it 'validates the filter_column objects' do
        expect(build(:procedure_presentation, "suivis_filters": [{ id: { column_id: "user/email", procedure_id: }, "filter": "not so long filter value" }])).to be_valid
        expect(build(:procedure_presentation, "suivis_filters": [{ id: { column_id: "user/email", procedure_id: }, "filter": "exceedingly long filter value" * 400 }])).to be_invalid
      end
    end
  end

  describe '#update_displayed_fields' do
    let(:en_construction_column) { procedure.find_column(label: 'Date de passage en construction') }
    let(:mise_a_jour_column) { procedure.find_column(label: 'Date du dernier évènement') }

    let(:procedure_presentation) do
      create(:procedure_presentation, assign_to:).tap do |pp|
        pp.update(sorted_column: SortedColumn.new(column: procedure.find_column(label: 'Demandeur'), order: 'desc'))
      end
    end

    subject do
      procedure_presentation.update(displayed_columns: [
        en_construction_column.id, mise_a_jour_column.id
      ])
    end

    it 'should update displayed_fields' do
      expect(procedure_presentation.displayed_columns).to eq(procedure.default_displayed_columns)

      subject

      expect(procedure_presentation.displayed_columns).to eq([
        en_construction_column, mise_a_jour_column
      ])
    end
  end
end
