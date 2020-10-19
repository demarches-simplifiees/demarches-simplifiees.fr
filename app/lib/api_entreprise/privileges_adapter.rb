class ApiEntreprise::PrivilegesAdapter < ApiEntreprise::Adapter
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
    ApiEntreprise::API.privileges(@token)
  end
end
