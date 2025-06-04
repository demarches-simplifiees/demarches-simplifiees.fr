# frozen_string_literal: true

class ErrorsController < ApplicationController
  rescue_from Exception do
    # catch any error, except errors triggered by middlewares outside controller (like warden middleware)
    render file: Rails.public_path.join('500.html'), layout: false, status: :internal_server_error
  end

  def internal_server_error
    # This dynamic template is rendered when a "normal" error occurs, (ie. a bug which is 99.99% of errors.)
    # However if this action fails (error in the view or in a middlewares)
    # the exceptions are rescued and a basic 100% static html file is rendererd instead.
    render_error 500
  end

  def not_found = render_error 404
  def unprocessable_entity = render_error 422

  def show # generic page for others errors
    @status = params[:status].to_i
    @error_name = Rack::Utils::HTTP_STATUS_CODES[@status]

    render_error @status
  end

  private

  def render_error(status)
    respond_to do |format|
      format.html { render status: }
      format.json { render status:, json: { status:, name: Rack::Utils::HTTP_STATUS_CODES[status] } }
    end
  end

  # Intercept errors in before_action when fetching user or roles
  # when db is unreachable so we can still display a nice 500 static page
  def current_user
    super
  rescue
    nil
  end

  def current_user_roles
    super
  rescue
    nil
  end
end
