# frozen_string_literal: true

class ProConnectInformation < ApplicationRecord
  self.table_name = 'agent_connect_informations'

  belongs_to :user
end
