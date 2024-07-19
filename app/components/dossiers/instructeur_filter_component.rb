class Dossiers::InstructeurFilterComponent < ApplicationComponent
  attr_reader :procedure, :procedure_presentation, :statut, :facet

  def initialize(procedure:, procedure_presentation:, statut:, facet: nil)
    @procedure = procedure
    @procedure_presentation = procedure_presentation
    @statut = statut
    @facet = facet
  end

  def facet_type = facet.present? ? facet.type : :text

  def options_for_select_of_field
    if facet.scope.present?
      I18n.t(facet.scope).map(&:to_a).map(&:reverse)
    elsif facet.table == 'groupe_instructeur'
      current_instructeur.groupe_instructeurs.filter_map do
        if _1.procedure_id == procedure.id
          [_1.label, _1.id]
        end
      end
    else
      find_type_de_champ(facet.column).options_for_select
    end
  end

  def filter_react_props
    {
      selected_key: facet.present? ? facet.id : '',
      items: procedure_presentation.filterable_fields_options,
      name: :field,
      id: 'search-filter',
      'aria-describedby': 'instructeur-filter-combo-label',
      form: 'filter-component',
      data: { no_autosubmit: 'input blur', no_autosubmit_on_empty: 'true', autosubmit_target: 'input' }
    }
  end

  private

  def find_type_de_champ(column)
    TypeDeChamp
      .joins(:revision_types_de_champ)
      .where(revision_types_de_champ: { revision_id: procedure.revisions })
      .order(created_at: :desc)
      .find_by(stable_id: column)
  end
end
