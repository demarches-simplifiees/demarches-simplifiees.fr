if LogStasher.enabled
  LogStasher.add_custom_fields do |fields|
    fields[:type] = "tps"
  end
end
