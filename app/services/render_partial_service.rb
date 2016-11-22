class RenderPartialService

  attr_accessor :controller, :method

  def initialize controller, method
    @controller = controller
    @method = method
  end

  def navbar
    retrieve_navbar
  end

  def left_panel
    retrieve_left_panel
  end

  private

  def retrieve_navbar
    'layouts/navbars/_navbar_' + retrieve_name
  end

  def retrieve_left_panel
    'layouts/left_panel/_leftpanel_' + retrieve_name
  end

  def retrieve_name
    controller.to_s.parameterize + '_' + method.to_s
  end
end