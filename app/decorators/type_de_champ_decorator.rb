
class TypeDeChampDecorator < Draper::Decorator
  delegate_all
  def button_up index
    h.button_tag '', class: %w(btn btn-default form-control fa fa-chevron-up), id: "btn_up_#{index}" unless index == 0
  end

  def button_down index
    h.button_tag '', class: %w(btn btn-default form-control fa fa-chevron-down), id: "btn_down_#{index}" if persisted?
  end
end