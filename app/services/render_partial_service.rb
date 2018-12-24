class RenderPartialService
  attr_accessor :controller, :method

  def initialize(controller, method)
    @controller = controller
    @method = method
  end

  def navbar
    retrieve_navbar
  end

  def left_panel
    retrieve_left_panel
  end

  def self.left_panel_exist?(left_panel_url)
    file = left_panel_url.split('/').last

    File.exist?(Rails.root.join('app', 'views', 'layouts', 'left_panels', "_#{file}.html.haml"))
  end

  private

  def retrieve_navbar
    "layouts/navbars/navbar_#{retrieve_name}"
  end

  def retrieve_left_panel
    "layouts/left_panels/left_panel_#{retrieve_name}"
  end

  def retrieve_name
    "#{controller.to_s.parameterize.underscore}_#{method.to_s}"
  end
end
