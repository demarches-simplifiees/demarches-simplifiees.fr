# frozen_string_literal: true

describe ProcedurePresentation do
  include ActiveSupport::Testing::TimeHelpers

  let(:procedure) { create(:procedure, :published, types_de_champ_public:, types_de_champ_private: [{}]) }
  let(:procedure_id) { procedure.id }
  let(:types_de_champ_public) { [{}] }
  let(:instructeur) { create(:instructeur) }
  let(:assign_to) { create(:assign_to, procedure:, instructeur:) }
  let(:first_type_de_champ) { assign_to.procedure.active_revision.types_de_champ_public.first }
  let(:first_type_de_champ_id) { first_type_de_champ.stable_id.to_s }
  let(:procedure_presentation) {
    create(:procedure_presentation,
      assign_to:,
      displayed_fields: [
        { label: "test1", table: "user", column: "email" },
        { label: "test2", table: "type_de_champ", column: first_type_de_champ_id }
      ],
      sort: { table: "user", column: "email", "order" => "asc" },
      filters: filters)
  }
  let(:procedure_presentation_id) { procedure_presentation.id }
  let(:filters) { { "a-suivre" => [], "suivis" => [{ "label" => "label1", "table" => "self", "column" => "created_at" }] } }

  def to_filter((label, filter)) = FilteredColumn.new(column: procedure.find_column(label: label), filter: filter)

  describe "#displayed_fields" do
    it { expect(procedure_presentation.displayed_fields).to eq([{ "label" => "test1", "table" => "user", "column" => "email" }, { "label" => "test2", "table" => "type_de_champ", "column" => first_type_de_champ_id }]) }
  end

  describe "#sort" do
    it { expect(procedure_presentation.sort).to eq({ "table" => "user", "column" => "email", "order" => "asc" }) }
  end

  describe "#filters" do
    it { expect(procedure_presentation.filters).to eq({ "a-suivre" => [], "suivis" => [{ "label" => "label1", "table" => "self", "column" => "created_at" }] }) }
  end

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
