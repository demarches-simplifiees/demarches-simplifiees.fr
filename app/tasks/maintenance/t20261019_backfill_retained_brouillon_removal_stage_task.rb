# frozen_string_literal: true

module Maintenance
  class T20261019BackfillRetainedBrouillonRemovalStageTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern

    run_on_first_deploy

    # The same date as DossierRemovalConcern#removal_notice_at, counted in Paris
    # time so that it does not move by an hour across a change of daylight
    # saving time.
    NOTICE_AT = <<~SQL.squish
      ((expired_at AT TIME ZONE 'UTC' AT TIME ZONE 'Europe/Paris')
        - make_interval(weeks => :weeks)) AT TIME ZONE 'Europe/Paris' AT TIME ZONE 'UTC'
    SQL

    # The brouillons out of the trash and never warned whose stage or notice
    # date disagrees with expired_at: kept before the retained stage existed,
    # or edited, extended or restored by the previous code while the deploy
    # was rolling out. Only those, so a run can be repeated once the previous
    # code is gone.
    def collection
      Dossier.state_brouillon
        .where(hidden_by_user_at: nil, hidden_by_expired_at: nil, brouillon_close_to_expiration_notice_sent_at: nil)
        .where("removal_stage IS DISTINCT FROM 'retained' OR removal_due_at IS DISTINCT FROM #{NOTICE_AT}", weeks:)
        .in_batches
    end

    def process(batch)
      batch.update_all(["removal_stage = 'retained', removal_due_at = #{NOTICE_AT}", { weeks: }])
    end

    private

    def weeks = Expired::REMAINING_WEEKS_BEFORE_EXPIRATION
  end
end
