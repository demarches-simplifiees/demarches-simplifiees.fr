# frozen_string_literal: true

class Instructeurs::BulkMessageFormComponent < ApplicationComponent
  attr_reader :current_instructeur, :procedure, :dossiers_count_per_groupe_instructeur

  def initialize(current_instructeur:, procedure:, dossiers_count_per_groupe_instructeur:)
    @current_instructeur = current_instructeur
    @procedure = procedure
    @dossiers_count_per_groupe_instructeur = dossiers_count_per_groupe_instructeur
  end

  def default_dossiers_count
    if procedure.routing_enabled
      @dossiers_count_per_groupe_instructeur.sum do |groupe_instructeur_id, dossier_count|
        if instructeur_in_all_groupes? || current_instructeur_in_groupe?(groupe_instructeur_id)
          dossier_count
        else
          0
        end
      end
    else
      @dossiers_count_per_groupe_instructeur.values.sum
    end
  end

  # grouped by groupe_instructeur_id, those without is indexed by nil
  def dossier_count_without_group = @dossiers_count_per_groupe_instructeur[nil]

  def groupe_instructeurs_with_brouillon = procedure.groupe_instructeurs.filter { dossier_count_for(_1)&.> 0 }

  def splitted_groupe_instructeurs = yield(*groupe_instructeurs_with_brouillon.partition { current_instructeur_in_groupe?(_1.id) })

  def groupe_instructeur_checkbox(form, groupe_instructeur)
    form.check_box(
      groupe_instructeur.id,
      {
        checked: current_instructeur_in_groupe?(groupe_instructeur.id),
      },
      'true',
      'false'
    )
  end

  def groupe_instructeur_label(form, groupe_instructeur)
    form.label groupe_instructeur.id, class: 'fr-label' do
      safe_join([
        groupe_instructeur.label,
        tag.span(class: 'fr-hint-text') do
          safe_join([
            t('.dossier_count_per_group', count: dossier_count_for(groupe_instructeur)),
            text_belongs_to_group(groupe_instructeur)
          ])
        end
      ])
    end
  end

  def instructeur_in_all_groupes? = @in_all_groupes ||= procedure.groupe_instructeurs.size == instructeur_groupe_ids.size

  private

  def dossier_count_for(groupe_instructeur) = @dossiers_count_per_groupe_instructeur[groupe_instructeur.id] || 0

  def current_instructeur_in_groupe?(groupe_instructeur_id) = groupe_instructeur_id.in?(instructeur_groupe_ids)

  def text_belongs_to_group(groupe_instructeur)
    if current_instructeur_in_groupe?(groupe_instructeur.id)
      tag.span(t('.present_in_group'))
    else
      tag.span(t('.not_present_in_group'))
    end
  end

  def instructeur_groupe_ids
    @instructeur_groupe_ids ||= current_instructeur
      .groupe_instructeurs
      .filter { _1.procedure_id == procedure.id }
      .map(&:id)
  end
end
