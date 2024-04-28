# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: copy user id to administrateurs.user_id, instructeurs.user_id and experts.user_id'
  task copy_user_association_to_user_related_models: :environment do
    rake_puts "Running deploy task 'copy_user_association_to_user_related_models'"

    copy_user_id_to(Administrateur)
    copy_user_id_to(Instructeur)
    copy_user_id_to(Expert)

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end

  def copy_user_id_to(model)
    table_name = model.table_name
    rake_print "Copying user.#{table_name.singularize}_id to #{table_name}.user_id"

    records_to_update = model.where(user_id: nil)
    progress = ProgressReport.new(records_to_update.count)

    records_to_update.where(user_id: nil).in_batches do |relation|
      count = relation.update_all("user_id = (SELECT id FROM users WHERE #{table_name}.id = users.#{table_name.singularize}_id)")
      progress.inc(count)
      sleep(0.01) # throttle
    end

    progress.finish
    rake_puts
  end
end
