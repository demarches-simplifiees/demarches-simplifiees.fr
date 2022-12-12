class API::Public::V1::BaseController < ApplicationController
  protected

  def render_missing_param(param_name)
    render_error("#{param_name} is missing", :bad_request)
  end

  def render_not_found(resource_name, resource_id)
    render_error("#{resource_name} #{resource_id} is not found", :not_found)
  end

  private

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
