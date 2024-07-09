# frozen_string_literal: true

class ExportItemType < ActiveRecord::Type::Value
  # form_input, or setter -> type
  def cast(value)
    value = value.deep_symbolize_keys if value.respond_to?(:deep_symbolize_keys)

    case value
    in ExportItem
      value
    in NilClass # default value
      nil
    # from db
    in { template: Hash, enabled: TrueClass | FalseClass } => h

      ExportItem.new(**h.slice(:template, :enabled, :stable_id))
    # from form
    in { template: String } => h

      template = JSON.parse(h[:template]).deep_symbolize_keys
      enabled = h[:enabled] == 'true'
      stable_id = h[:stable_id]&.to_i
      ExportItem.new(template:, enabled:, stable_id:)
    end
  end

  # db -> ruby
  def deserialize(value) = cast(value&.then { JSON.parse(_1) })

  # ruby -> db
  def serialize(value)
    return nil if value.nil?

    if value.is_a?(ExportItem)
      JSON.generate({
        template: value.template,
        enabled: value.enabled,
        stable_id: value.stable_id
      }.compact)
    else
      raise ArgumentError, "Invalid value for ExportItem serialization: #{value}"
    end
  end
end
