# frozen_string_literal: true

class API::Public::V1::BaseController < ApplicationController
  skip_forgery_protection

  before_action :check_content_type_is_json, if: -> { request.post? || request.patch? || request.put? }

  before_action do
    Current.browser = 'api'
  end

  protected

  def render_missing_param(param_name)
    render_error("#{param_name} is missing", :bad_request)
  end

  def render_bad_request(error_message)
    render_error(error_message, :bad_request)
  end

  def render_not_found(resource_name, resource_id)
    render_error("#{resource_name} #{resource_id} is not found", :not_found)
  end

  private

  def check_content_type_is_json
    render_error("Content-Type should be json", :bad_request) unless request.headers['Content-Type'] == 'application/json'
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
