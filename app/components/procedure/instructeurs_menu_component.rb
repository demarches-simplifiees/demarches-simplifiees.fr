# frozen_string_literal: true

class Procedure::InstructeursMenuComponent < ApplicationComponent
  def initialize(procedure:)
    @procedure = procedure
  end

  private

  def links
    first_option, first_icon = if @procedure.groupe_instructeurs.one?
      instructeurs_count = @procedure.groupe_instructeurs.first.instructeurs.count
      [t('.instructeurs', count: instructeurs_count), 'fr-icon-user-line']
    else
      ["#{@procedure.groupe_instructeurs.count} groupes", 'fr-icon-group-line']
    end

    [
      { name: first_option, url: admin_procedure_groupe_instructeurs_path(@procedure), icon: "#{first_icon} fr-icon--sm" },
      { name: 'Options', url: options_admin_procedure_groupe_instructeurs_path(@procedure), icon: 'fr-icon-settings-5-line fr-icon--sm' }
    ].compact
  end
end
