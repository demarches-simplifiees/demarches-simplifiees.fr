# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: fix_include_in_logic'
  task fix_include_in_logic: :environment do
    include Logic
    puts "Running deploy task 'fix_include_in_logic'"

    tdcs_with_condition = TypeDeChamp.where.not(condition: nil)

    progress = ProgressReport.new(tdcs_with_condition.count)

    tdcs_with_condition.find_each do |tdc|
      begin
        tdc.revisions.each do |revision|
          tdcs = revision.types_de_champ.where(stable_id: tdc.condition.sources)

          transformed_condition = transform_eq_to_include(tdc.condition, tdcs)

          if (transformed_condition != tdc.condition)
            rake_puts "found #{tdc.id}, original: #{tdc.condition.to_s(tdcs)}, correction: #{transformed_condition.to_s(tdcs)}!"
            new_tdc = revision.find_and_ensure_exclusive_use(tdc.stable_id)
            new_tdc.update_columns(condition: transformed_condition)
            Champ.joins(:dossier).where(dossier: { revision: revision }, type_de_champ: tdc).update(type_de_champ: new_tdc)
          end
        end
      rescue StandardError => e
        rake_puts "problem with tdc #{tdc.id},\ncondition: #{tdc.read_attribute_before_type_cast('condition')},\nmessage: #{e.message}"
      ensure
        progress.inc
      end
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end

  def transform_eq_to_include(condition, tdcs)
    case condition
    when Logic::NAryOperator
      condition.class.new(condition.operands.map { transform_eq_to_include(_1, tdcs) })
    when Eq
      target = tdcs.find { _1.stable_id == condition.left.stable_id }
      if target.type_champ == 'multiple_drop_down_list'
        ds_include(condition.left, condition.right)
      else
        condition
      end
    else
      condition
    end
  end
end
