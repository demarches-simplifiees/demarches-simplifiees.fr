# frozen_string_literal: true

describe '20201001161931_migrate_filters_to_use_stable_id' do
  let(:rake_task) { Rake::Task['after_party:remove_migration_status_on_filters'] }

  let(:procedure) { create(:simple_procedure) }
  let(:instructeur_1) { create(:instructeur) }
  let(:instructeur_2) { create(:instructeur) }

  let(:assign_to_1) { create(:assign_to, procedure: procedure, instructeur: instructeur_1) }
  let(:assign_to_2) { create(:assign_to, procedure: procedure, instructeur: instructeur_2) }

  let(:procedure_presentation_with_migration) { create(:procedure_presentation, assign_to: assign_to_1, filters: filters.merge('migrated': true)) }
  let(:procedure_presentation_without_migration) { create(:procedure_presentation, assign_to: assign_to_2, filters: filters) }

  let(:filters) do
    { "suivis" => [{ "table" => "user", "column" => "email", "value" => "test@example.com" }] }
  end

  subject(:run_task) do
    procedure_presentation_with_migration
    procedure_presentation_without_migration

    rake_task.invoke

    procedure_presentation_with_migration.reload
    procedure_presentation_without_migration.reload
  end

  after { rake_task.reenable }

  context 'when the procedure presentation has a "migrated" key' do
    it 'removes the "migrated" key' do
      run_task
      expect(procedure_presentation_with_migration.filters).not_to have_key('migrated')
    end

    it 'leaves other keys unchanged' do
      run_task
      expect(procedure_presentation_with_migration.filters['suivis']).to be_present
    end
  end

  context 'when the procedure presentation doesn’t have a "migrated" key' do
    it 'leaves keys unchanged' do
      run_task
      expect(procedure_presentation_without_migration.filters['suivis']).to be_present
    end
  end

  context 'when the procedure presentation is invalid' do
    before do
      procedure_presentation_with_migration.update_column(
        :sort,
       { table: 'invalid-table', column: 'invalid-column', order: 'invalid-order' }
      )
    end

    it 'removes the "migrated" key properly' do
      run_task
      expect(procedure_presentation_with_migration).not_to be_valid
      expect(procedure_presentation_with_migration.filters).not_to have_key('migrated')
    end

    it 'leaves the other keys unchanged' do
      run_task
      expect(procedure_presentation_without_migration.filters['suivis']).to be_present
    end
  end
end
