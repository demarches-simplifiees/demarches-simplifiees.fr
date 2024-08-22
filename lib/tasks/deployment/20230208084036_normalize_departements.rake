# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: normalize_departements'
  task normalize_departements: :environment do
    puts "Running deploy task 'normalize_departements'"

    scope_external_id_nil = Champs::DepartementChamp.where(external_id: nil)
    scope_external_id_empty = Champs::DepartementChamp.where(external_id: '')
    scope_external_id_present = Champs::DepartementChamp.where.not(external_id: [nil, ''])

    progress = ProgressReport.new(scope_external_id_nil.count + scope_external_id_empty.count + scope_external_id_present.count)

    normalize_asynchronously(scope_external_id_nil, progress, Migrations::NormalizeDepartementsWithNilExternalIdJob)
    normalize_asynchronously(scope_external_id_empty, progress, Migrations::NormalizeDepartementsWithEmptyExternalIdJob)
    normalize_asynchronously(scope_external_id_present, progress, Migrations::NormalizeDepartementsWithPresentExternalIdJob)

    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end

  private

  def normalize_asynchronously(scope, progress, job)
    scope.pluck(:id).in_groups_of(10_000, false) do |champ_ids|
      job.perform_later(champ_ids)
      progress.inc(champ_ids.count)
    end
  end
end
