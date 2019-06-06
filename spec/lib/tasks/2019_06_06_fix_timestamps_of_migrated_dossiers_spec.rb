describe '2019_06_06_fix_timestamps_of_migrated_dossiers' do
  let(:affected_procedure) { create(:simple_procedure, id: 500) }
  let(:procedure_outside_range) { create(:simple_procedure, id: 5000) }

  let(:affected_dossier) { create(:dossier, procedure: affected_procedure) }
  let(:dossier_outside_time_range) { create(:dossier, procedure: affected_procedure) }
  let(:dossier_outside_procedure_range) { create(:dossier, procedure: procedure_outside_range) }

  let(:creation_time) { Time.utc(2017, 1, 1, 12, 0) }
  let(:en_construction_time) { Time.utc(2018, 1, 1, 12, 0) }
  let(:pj_migration_time) { Time.utc(2019, 6, 4, 12, 0) }

  let(:rake_task) { Rake::Task['fix_timestamps_of_migrated_dossiers:run'] }

  before do
    Timecop.freeze(creation_time) do
      affected_dossier
      dossier_outside_time_range
      dossier_outside_procedure_range
    end
    Timecop.freeze(en_construction_time) do
      affected_dossier.update_column(:en_construction_at, Time.zone.now)
    end
    Timecop.freeze(pj_migration_time.prev_week) do
      dossier_outside_time_range.tap(&:touch).reload
    end
    Timecop.freeze(pj_migration_time) do
      dossier_outside_procedure_range.tap(&:touch).reload
      affected_dossier.tap(&:touch).reload
    end

    rake_task.invoke
  end

  after { rake_task.reenable }

  it 'fix the updated_at of affected dossiers' do
    expect(affected_dossier.reload.updated_at).to eq(en_construction_time)
  end

  it 'ignores dossiers with a procedure_id outside of the procedure range' do
    expect(dossier_outside_procedure_range.reload.updated_at).to eq(pj_migration_time)
  end

  it 'ignores dossiers with an updated_at outside of the time range' do
    expect(dossier_outside_time_range.reload.updated_at).to eq(pj_migration_time.prev_week)
  end
end
