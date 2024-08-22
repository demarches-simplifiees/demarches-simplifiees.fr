# frozen_string_literal: true

class RemoveConstraintOnAgentConnectInformation < ActiveRecord::Migration[7.0]
  def change
    # make given_name, usual_name nullable
    change_column_null :agent_connect_informations, :given_name, true
    change_column_null :agent_connect_informations, :usual_name, true
  end
end
