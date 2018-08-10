if LogStasher.enabled
  LogStasher.add_custom_fields do |fields|
    fields[:type] = "tps"
  end

  LogStasher.add_custom_fields_to_request_context do |fields|
    fields.merge!(session_info_payload)
  end
end
