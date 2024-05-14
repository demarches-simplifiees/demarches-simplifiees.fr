# frozen_string_literal: true

class Conditions::ConditionsErrorsComponent < ApplicationComponent
  def initialize(conditions:, source_tdcs:)
    @conditions, @source_tdcs = conditions, source_tdcs
  end

  private

  def errors
    errors = @conditions
      .flat_map { |condition| condition.errors(@source_tdcs) }
      .uniq

    # if a tdc is not available (has been removed for example)
    # it causes a lot of errors (incompatible type for example)
    # only the root cause is displayed
    messages = if errors.include?({ type: :not_available })
      [t('not_available', scope: '.errors')]
    else
      errors.map { |error| humanize(error) }
    end

    to_html_list(messages)
  end

  def to_html_list(messages)
    messages
      .map { |message| tag.li(message) }
      .then { |lis| tag.ul(lis.reduce(&:+)) }
  end

  def humanize(error)
    case error
    in { type: :not_available }
    in { type: :incompatible, stable_id: nil }
      t('not_available', scope: '.errors')
    in { type: :unmanaged, stable_id: stable_id }
      targeted_champ = @source_tdcs.find { |tdc| tdc.stable_id == stable_id }
      t('unmanaged',
        scope: '.errors',
        libelle: targeted_champ.libelle,
        type_champ: t(targeted_champ.type_champ, scope: 'activerecord.attributes.type_de_champ.type_champs')&.downcase)
    in { type: :incompatible, stable_id: stable_id, right: right, operator_name: operator_name }
      targeted_champ = @source_tdcs.find { |tdc| tdc.stable_id == stable_id }
      t('incompatible', scope: '.errors',
        libelle: targeted_champ.libelle,
        type_champ: t(targeted_champ.type_champ, scope: 'activerecord.attributes.type_de_champ.type_champs')&.downcase,
        operator: t(operator_name, scope: 'logic.operators').downcase,
        right: right.to_s.downcase)
    in { type: :required_number, operator_name: operator_name }
      t('required_number', scope: '.errors',
        operator: t(operator_name, scope: 'logic.operators'))
    in { type: :not_included, stable_id: stable_id, right: right }
      targeted_champ = @source_tdcs.find { |tdc| tdc.stable_id == stable_id }
      t('not_included', scope: '.errors',
        libelle: targeted_champ.libelle,
        right: right.to_s.downcase)
    in { type: :required_list }
      t('required_list', scope: '.errors')
    in { type: :required_include, operator_name: "Logic::Eq" }
      t("required_include.eq", scope: '.errors')
    in { type: :required_include, operator_name: "Logic::NotEq" }
      t("required_include.not_eq", scope: '.errors')
    else
      nil
    end
  end

  def render?
    @conditions
      .filter { |condition| condition.errors(@source_tdcs).present? }
      .present?
  end
end
