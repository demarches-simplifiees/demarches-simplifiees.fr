# == Schema Information
#
# Table name: type_de_champ_conditions
#
#  id                             :bigint           not null, primary key
#  operator                       :string           not null
#  value                          :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  source_type_de_champ_stable_id :bigint           not null
#  type_de_champ_id               :bigint           not null
#
class TypeDeChampCondition < ApplicationRecord
  belongs_to :type_de_champ

  before_save :source_type_de_champ_change, if: -> { source_type_de_champ_stable_id_changed? }

  def source_coordinate(revision)
    if source_type_de_champ_stable_id.present?
      revision.coordinate_for(type_de_champ)
        .siblings
        .find { |coordinate| coordinate.stable_id == source_type_de_champ_stable_id }
    end
  end

  def source_type_de_champ(revision)
    source_coordinate(revision)&.type_de_champ
  end

  def valid_for_revision?(revision)
    source_valid?(revision) && operator.present? && value_valid?(revision)
  end

  private

  def source_type_de_champ_change
    revision = type_de_champ.procedure.draft_revision
    self.value = source_type_de_champ(revision)&.default_condition_value
  end

  def source_valid?(revision)
    source_type_de_champ(revision).present? && revision.coordinate_for(type_de_champ)
      .siblings_that_can_have_conditional_logic
      .includes?(source_coordinate)
  end

  def value_valid?(revision)
    if value.present?
      condition_values = source_type_de_champ(revision)&.condition_values
      condition_values.is_a?(Array) ? condition_values.values.map(&:to_s).find { |maybe_value| maybe_value.to_s == value } : true
    else
      true
    end
  end
end
