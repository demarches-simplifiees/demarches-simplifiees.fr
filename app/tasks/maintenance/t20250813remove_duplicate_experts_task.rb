# frozen_string_literal: true

module Maintenance
  class T20250813removeDuplicateExpertsTask < MaintenanceTasks::Task
    # Documentation: cette tâche permet de supprimer les experts qui ont un même
    # user_id en ne conservant que le plus ancien.
    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    # Uncomment only if this task MUST run imperatively on its first deployment.
    # If possible, leave commented for manual execution later.
    run_on_first_deploy

    def collection
      duplicate_user_ids = Expert
        .group(:user_id)
        .having('COUNT(*) > 1')
        .pluck(:user_id)

      Expert
        .where(user_id: duplicate_user_ids)
        .order(:created_at)
        .group_by(&:user_id)
        .flat_map { |_, experts| experts.drop(1) }
    end

    def process(expert)
      expert.destroy!
    end
  end
end
