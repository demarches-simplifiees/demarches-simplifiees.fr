# frozen_string_literal: true

class APIEntreprise::PrivilegesAdapter < APIEntreprise::Adapter
  def initialize(token)
    @token = token
  end

  def valid?
    begin
      get_resource
      true
    rescue
      false
    end
  end

  private

  def get_resource
    api.tap do
      _1.token = @token
    end.privileges
  end
end
