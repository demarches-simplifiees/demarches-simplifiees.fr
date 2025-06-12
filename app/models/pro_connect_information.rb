# frozen_string_literal: true

class ProConnectInformation < ApplicationRecord
  self.table_name = 'agent_connect_informations'

  self.ignored_columns += ["instructeur_id"]
  belongs_to :user
end
