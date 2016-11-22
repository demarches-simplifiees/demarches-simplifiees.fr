class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_action :check_browser
  before_action :load_navbar_left_pannel_partial_url

  def default_url_options
    return { protocol: 'https' } if Rails.env.staging? || Rails.env.production?
    {}
  end

  def check_browser
    BROWSER.value = Browser.new(request.user_agent)
  end

  def load_navbar_left_pannel_partial_url
    controller = request.controller_class
    method = params[:action]
    service = RenderPartialService.new(controller, method)
    @navbar_url = service.navbar
    @left_pannel_url = service.left_panel
    @facade_data_view = nil
  end
end
