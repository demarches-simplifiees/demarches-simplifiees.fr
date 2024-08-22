# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_child_types_de_champ'
  task fix_child_types_de_champ: :environment do
    puts "Running deploy task 'fix_child_types_de_champ'"

    children = TypeDeChamp.where.not(parent_id: nil).where.missing(:revision_types_de_champ).includes(parent: :revision_types_de_champ)
    progress = ProgressReport.new(children.count)

    children.find_each do |type_de_champ|
      type_de_champ.parent.revision_types_de_champ.each do |revision_type_de_champ|
        ProcedureRevisionTypeDeChamp.create(parent: revision_type_de_champ,
          type_de_champ: type_de_champ,
          revision_id: revision_type_de_champ.revision_id,
          position: type_de_champ.order_place)
      end
      progress.inc
    end
    progress.finish

    children = TypeDeChamp.where.not(parent_id: nil).includes(:revision_types_de_champ, parent: :revision_types_de_champ)
    progress = ProgressReport.new(children.count)

    children.find_each do |type_de_champ|
      prtdcs = type_de_champ.parent.revision_types_de_champ
      rtdcs = type_de_champ.revision_types_de_champ

      if prtdcs.size > rtdcs.size
        missing_rtdcs = prtdcs.filter { |prtdc| !prtdc.revision_id.in?(rtdcs.map(&:revision_id)) }

        missing_rtdcs.each do |revision_type_de_champ|
          ProcedureRevisionTypeDeChamp.create(parent: revision_type_de_champ,
            type_de_champ: type_de_champ,
            revision_id: revision_type_de_champ.revision_id,
            position: type_de_champ.order_place)
        end
      end
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
