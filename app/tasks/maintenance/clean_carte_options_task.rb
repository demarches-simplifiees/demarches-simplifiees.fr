# frozen_string_literal: true

module Maintenance
  class CleanCarteOptionsTask < MaintenanceTasks::Task
    # In the rest of PR 10713
    # TypeDeChamp options may contain options which are not consistent with the
    # type_champ (e.g. a 'carte' TypeDeChamp which has a
    # drop_down_options key/value in its options).
    # The aim here is to clean up the options so that only those wich are useful
    # for the type_champ in question, here: those in TypesDeChamp::CarteTypeDeChamp::LAYERS

    LAYERS = TypesDeChamp::CarteTypeDeChamp::LAYERS.map(&:to_s)

    def collection
      TypeDeChamp
        .where(type_champ: 'carte')
        .where.not(options: {})
        .where.not(
          "(SELECT COUNT(*) FROM jsonb_each_text(options)) = #{LAYERS.size} AND " +
            LAYERS.map { |layer| "options ? '#{layer}'" }.join(' AND ')
        )
    end

    def process(tdc)
      tdc.update(options: tdc.options.slice(*LAYERS))
    end
  end
end
