# frozen_string_literal: true

class Instructeurs::CellComponent < ApplicationComponent
  include DossierHelper

  def initialize(dossier:, column:)
    @dossier = dossier
    @column = column
  end

  def call
    advanced_layout || simple_layout
  end

  private

  def advanced_layout
    if @column.email?
      email_and_tiers(@dossier)
    elsif @column.dossier_labels?
      tags_label(@dossier.labels)
    elsif @column.avis?
      sum_up_avis(@dossier.avis)
    end
  end

  def simple_layout
    raw_value = raw_value_for_column(@dossier, @column)
    return '' if raw_value.nil?

    format(raw_value, @column.type)
  end

  def raw_value_for_column(dossier, column)
    data = if @column.champ_column?
      @dossier.champs.find { _1.stable_id == column.stable_id }
    else
      @dossier
    end

    @column.value(data)
  end

  def format(raw_value, type)
    case @column.type
    when :boolean
      if @column.tdc_type == 'checkbox'
        raw_value ? I18n.t('activerecord.attributes.type_de_champ.type_champs.checkbox_true') : ''
      else
        raw_value ? I18n.t('utils.yes') : I18n.t('utils.no')
      end
    when :attachements
      raw_value.present? ? 'présent' : 'absent'
    when :enum
      format_enum(column: @column, raw_value:)
    when :enums
      format_enums(column: @column, raw_values: raw_value)
    when :date
      raw_value = Date.parse(raw_value) if raw_value.is_a?(String)
      I18n.l(raw_value)
    when :datetime
      raw_value = DateTime.parse(raw_value) if raw_value.is_a?(String)
      I18n.l(raw_value)
    else
      raw_value
    end
  end

  def format_enums(column:, raw_values:)
    raw_values.map { format_enum(column:, raw_value: _1) }.join(', ')
  end

  def format_enum(column:, raw_value:)
    # options for select store ["trad", :enum_value]
    selected_option = @column.options_for_select.find { _1[1].to_s == raw_value }

    selected_option ? selected_option.first : raw_value
  end

  def email_and_tiers(dossier)
    email = dossier&.user&.email

    if dossier.for_tiers
      prenom, nom = dossier&.individual&.prenom, dossier&.individual&.nom
      "#{email} #{I18n.t('views.instructeurs.dossiers.acts_on_behalf')} #{prenom} #{nom}"
    else
      email
    end
  end

  def sum_up_avis(avis)
    avis.map(&:question_answer)&.compact&.tally
      &.map { |k, v| I18n.t("helpers.label.question_answer_with_count.#{k}", count: v) }
      &.join(' / ')
  end
end
