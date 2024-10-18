# frozen_string_literal: true

module Maintenance
  class CleanHeaderSectionOptionsTask < MaintenanceTasks::Task
    # Dans la suite de la PR 10713
    # Il est possible que dans les options des TypeDeChamp soient présentes des
    # options qui ne sont pas cohérentes avec le type_champ (ex: un TypeDeChamp
    # "header_section" qui a dans ses options une clé/valeur drop_down_options)
    # Il s'agit donc ici de nettoyer les options de sorte à ce qu'il ne reste
    # que les options liées au type_champ considéré.
    def collection
      TypeDeChamp
        .where(type_champ: 'header_section')
        .where.not(options: {})
        .where.not("(SELECT COUNT(*) FROM jsonb_each_text(options)) = 1 AND options ? 'header_section_level'")
    end

    def process(tdc)
      tdc.update(options: tdc.options.slice(:header_section_level))
    end
  end
end
