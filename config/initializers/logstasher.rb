if LogStasher.enabled
  LogStasher.add_custom_fields do |fields|
    fields[:type] = "tps"
  end

  LogStasher.watch('process_action.action_controller') do |name, start, finish, id, payload, store|
    store[:user_agent] = payload[:user_agent]
    store[:browser] = payload[:browser]
    store[:browser_version] = payload[:browser_version]
    store[:platform] = payload[:platform]

    store[:current_user_roles] = payload[:current_user_roles]

    if payload[:current_user].present?
      store[:current_user_id] = payload[:current_user][:id]
      store[:current_user_email] = payload[:current_user][:email]
    end
  end
end
