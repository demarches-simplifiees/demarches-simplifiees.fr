# frozen_string_literal: true

class Instructeurs::CellComponent < ApplicationComponent
  def initialize(dossier:, column:)
    @dossier = dossier
    @column = column
  end

  def call
    tag.span(value)
  end

  private

  def value
    custom_format = if @column.email?
      email_and_tiers(@dossier)
    elsif @column.dossier_labels?
      helpers.tags_label(@dossier.labels)
    elsif @column.avis?
      sum_up_avis(@dossier.avis)
    # needed ?
    elsif @column.column == 'sva_svr_decision_on'
      raise
      @column.value(@dossier)
    end

    return custom_format if custom_format.present?

    value = @column.champ_column? ? @column.value(champ_for(@column)) : @column.value(@dossier)

    return '' if value.nil?

    case @column.type
    when :boolean
      if @column.tdc_type == 'checkbox'
        value ? 'coché' : ''
      else
        value ? 'Oui' : 'Non'
      end
    when :attachements
      value.present? ? 'présent' : 'absent'
    when :enum
      format_enum(column: @column, value:)
    when :enums
      format_enums(column: @column, values: value)
    when :datetime, :date
      I18n.l(value)
    else
      value
    end
  end

  def format_enums(column:, values:)
    values.map { format_enum(column:, value: _1) }.join(', ')
  end

  def format_enum(column:, value:)
    # options for select store ["trad", :enum_value]
    selected_option = @column.options_for_select.find { _1[1].to_s == value }

    selected_option ? selected_option.first : value
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

  def champ_for(column) = @dossier.champs.find { _1.stable_id == column.stable_id }
end
