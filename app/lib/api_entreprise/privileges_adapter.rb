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
    APIEntreprise::API.privileges(@token)
  end
end
