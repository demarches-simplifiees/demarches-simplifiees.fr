module ApplicationHelper
  def flash_class(level)
    case level
    when "notice" then "alert-success"
    when "alert" then "alert-danger"
    end
  end
end
