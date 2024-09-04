# frozen_string_literal: true

module Maintenance
  # a previous commit : https://github.com/demarches-simplifiees/demarches-simplifiees.fr/pull/10625/commits/305b8c13c75a711a85521d0b19659293d8d92805
  #   the previous brokes a naming convention on ProcedurePresentation.filters|displayed_fields|sort
  # this commit
  #   it adjusts live data to fit new convention and avoid validation error
  class HotfixFormerProcedurePresentationNamingTask < MaintenanceTasks::Task
    def collection
      ProcedurePresentation.all
    end

    def process(element)
      element.displayed_fields = element.displayed_fields.map do |displayed_field|
        if displayed_field['table'] == 'type_de_champ_private'
          displayed_field['table'] = 'type_de_champ'
        end
        displayed_field
      end
      element.filters.map do |status, filters_by_status|
        element.filters[status] = filters_by_status.map do |filter_by_status|
          if filter_by_status['table'] == 'type_de_champ_private'
            filter_by_status['table'] = 'type_de_champ'
          end
          filter_by_status
        end
      end
      if element.sort['table'] == 'type_de_champ_private'
        element.sort['table'] = 'type_de_champ'
      end
      element.save!
    rescue ActiveRecord::RecordInvalid
      # do nothing, former invalid ProcedurePresentation still exist
      # cf: La validation a échoué : Le champ « Displayed fields » etablissement.entreprise_siren n’est pas une colonne permise
    end
  end
end
