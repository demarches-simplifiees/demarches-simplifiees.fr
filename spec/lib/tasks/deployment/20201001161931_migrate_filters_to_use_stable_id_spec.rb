# frozen_string_literal: true

describe '20201001161931_migrate_filters_to_use_stable_id' do
  let(:rake_task) { Rake::Task['after_party:migrate_filters_to_use_stable_id'] }

  let(:procedure) { create(:procedure, :with_instructeur, :with_type_de_champ) }
  let(:type_de_champ) { procedure.active_revision.types_de_champ_public.first }
  let(:sort) do
    {
      "table" => "type_de_champ",
      "column" => type_de_champ.id.to_s,
      "order" => "asc"
    }
  end
  let(:filters) do
    {
      'tous' => [
        {
          "label" => "test",
          "table" => "type_de_champ",
          "column" => type_de_champ.id.to_s,
          "value" => "test"
        }
      ],
      'suivis' => [],
      'traites' => [],
      'a-suivre' => [],
      'archives' => []
    }
  end
  let(:displayed_fields) do
    [
      {
        "label" => "test",
        "table" => "type_de_champ",
        "column" => type_de_champ.id.to_s
      }
    ]
  end
  let!(:procedure_presentation) do
    type_de_champ.update_column(:stable_id, 13)
    procedure_presentation = create(:procedure_presentation, procedure: procedure, assign_to: procedure.groupe_instructeurs.first.assign_tos.first)
    procedure_presentation.update_columns(sort: sort, filters: filters, displayed_fields: displayed_fields)
    procedure_presentation
  end

  before do
    rake_task.invoke
    procedure_presentation.reload
  end

  after { rake_task.reenable }

  context "should migrate procedure_presentation" do
    it "columns are updated" do
      expect(procedure_presentation.sort['column']).to eq(type_de_champ.stable_id.to_s)
      expect(procedure_presentation.filters['tous'][0]['column']).to eq(type_de_champ.stable_id.to_s)
      expect(procedure_presentation.displayed_fields[0]['column']).to eq(type_de_champ.stable_id.to_s)
      expect(procedure_presentation.filters['migrated']).to eq(true)
    end
  end
end
