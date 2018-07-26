require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2018_07_24_refresh_search_terms' do
  task run: :environment do
    # For dossiers belonging to an archived procedure, the check for the `build_default_individual` `after_save` callback fails.
    # So, we filter those out by joining with `procedure`, whose default scope excludes archived procedures.
    ds = Dossier.joins(:procedure)
    total_count = ds.count
    one_percent = total_count / 100
    Dossier.joins(:procedure).find_each(batch_size: 100).with_index do |d, i|
      if i % one_percent == 0
        rake_puts("#{i}/#{total_count} (#{i / one_percent}%)")
      end
      d.save(touch: false)
    end
  end
end
