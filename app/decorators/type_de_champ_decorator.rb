
class TypeDeChampDecorator < Draper::Decorator
  delegate_all
  def button_up params
    h.button_tag '', class: up_classes, id: "btn_up_#{params[:index]}", remote: true, method: :post if display_up_button?(params[:index])
  end

  def button_down params
    h.button_tag '', class: down_classes, id: "btn_down_#{params[:index]}", remote: true if display_down_button?(params[:index])
  end

  private

  def up_classes
    base_classes << 'fa-chevron-up'
  end

  def down_classes
    base_classes << 'fa-chevron-down'
  end

  def base_classes
    %w(btn btn-default form-control fa)
  end

  def display_up_button?(index)
    !(index == 0 || count_type_de_champ < 2)
  end

  def display_down_button?(index)
    (index + 1) < count_type_de_champ
  end

  def count_type_de_champ
    @count_type_de_champ ||= procedure.types_de_champ.count
  end
end