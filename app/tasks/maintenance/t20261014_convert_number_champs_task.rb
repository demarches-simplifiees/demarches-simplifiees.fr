# frozen_string_literal: true

module Maintenance
  class T20261014ConvertNumberChampsTask < MaintenanceTasks::Task
    # Convertit les champs number, masqués depuis 2020, en nombre entier ou décimal avant le retrait du type.

    LEGACY_TYPE_CHAMP = 'number'
    LEGACY_CHAMP_TYPE = 'Champs::NumberChamp'
    UNIT_SUFFIX = /[[:space:]]*[%€][[:space:]]*\z/
    CHAMP_TYPES = {
      integer_number: 'Champs::IntegerNumberChamp',
      decimal_number: 'Champs::DecimalNumberChamp',
    }.freeze

    def collection
      TypeDeChamp.where(type_champ: LEGACY_TYPE_CHAMP).distinct.pluck(:stable_id)
    end

    def process(stable_id)
      champs = ChampData.where(stable_id:, type: LEGACY_CHAMP_TYPE)
      values = champs.where.not("value ~ ?", '^-?[0-9]+$').pluck(:id, :value)
      target = values.any? { |_, value| integer_value(value).nil? && decimal_value(value) } ? :decimal_number : :integer_number

      values.each do |id, value|
        cleaned = target == :integer_number ? integer_value(value) : decimal_value(value)
        ChampData.where(id:).update_all(value: cleaned) if cleaned && cleaned != value
      end

      champs.in_batches.update_all(type: CHAMP_TYPES.fetch(target))
      TypeDeChamp
        .where(stable_id:, type_champ: LEGACY_TYPE_CHAMP)
        .update_all(type_champ: TypeDeChamp.type_champs.fetch(target))
    end

    private

    def integer_value(value)
      normalized = NumberFormatValidator.normalize(value.sub(UNIT_SUFFIX, ''))
      normalized if normalized.match?(NumberFormatValidator::INTEGER_FORMAT)
    end

    def decimal_value(value)
      normalized = NumberFormatValidator.normalize(value.sub(UNIT_SUFFIX, ''), decimal: true)
      normalized if normalized.match?(NumberFormatValidator::DECIMAL_FORMAT)
    end
  end
end
