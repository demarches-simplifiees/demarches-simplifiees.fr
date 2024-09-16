# frozen_string_literal: true

describe '20240912151317_clean_virtual_column_from_procedure_presentation.rake' do
  let(:rake_task) { Rake::Task['after_party:clean_virtual_column_from_procedure_presentation'] }

  let(:procedure) { create(:procedure) }
  let(:instructeur) { create(:instructeur) }
  let(:assign_to) { create(:assign_to, procedure:, instructeur:) }

  let!(:procedure_presentation) do
    displayed_fields = [{ label: "test1", table: "user", column: "email", virtual: true }]

    create(:procedure_presentation, assign_to:, displayed_fields:)
  end

  before do
    rake_task.invoke

    procedure_presentation.reload
  end

  after { rake_task.reenable }

  it 'removes the virtual field' do
    expect(procedure_presentation.displayed_fields).to eq([{ "column" => "email", "label" => "test1", "table" => "user" }])
  end
end
