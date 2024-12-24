# frozen_string_literal: true

module Maintenance
  class CleanTextAreaOptionsTask < MaintenanceTasks::Task
    # In the rest of PR 10713
    # TypeDeChamp options may contain options which are not consistent with the
    # type_champ (e.g. a ‘textarea’ TypeDeChamp which has a
    # drop_down_options key/value in its options).
    # The aim here is to clean up the options so that only those wich are useful
    # for the type_champ in question, here: "character_limit"

    def collection
      TypeDeChamp
        .where(type_champ: 'textarea')
        .where.not(options: {})
        .where.not("(SELECT COUNT(*) FROM jsonb_each_text(options)) = 1 AND options ? 'character_limit'")
    end

    def process(tdc)
      tdc.update(options: tdc.options.slice(:character_limit))
    end
  end
end
