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
      Expert
        .group(:user_id)
        .having('COUNT(*) > 1')
        .pluck(:user_id)
        .flat_map do |user_id|
          experts = Expert.where(user_id: user_id).order(:created_at)
          expert_to_keep = experts.first
          experts.drop(1).map { |expert_to_destroy| [expert_to_destroy, expert_to_keep] }
        end
    end

    def process((expert_to_destroy, expert_to_keep))
      Expert.transaction do
        Commentaire.where(expert: expert_to_destroy).update_all(expert_id: expert_to_keep.id)

        ExpertsProcedure.where(expert: expert_to_destroy).find_each do |ep|
          if ExpertsProcedure.exists?(expert: expert_to_keep, procedure_id: ep.procedure_id)
            ep.destroy!
          else
            ep.update!(expert: expert_to_keep)
          end
        end

        expert_to_destroy.destroy!
      end
    end
  end
end
