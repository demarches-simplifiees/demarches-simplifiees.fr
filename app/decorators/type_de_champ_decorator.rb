class TypeDeChampDecorator < Draper::Decorator
  delegate_all

  def button_up(params)
    h.link_to '', params[:url], class: up_classes,
                                id: "btn_up_#{params[:index]}",
                                remote: true,
                                method: :post,
                                style: display_up_button?(params[:index], params[:private]) ? '' : 'visibility: hidden;'
  end

  def button_down(params)
    h.link_to '', params[:url], class: down_classes,
                                id: "btn_down_#{params[:index]}",
                                remote: true,
                                method: :post,
                                style: display_down_button?(params[:index], params[:private]) ? '' : 'visibility: hidden;'
  end

  private

  def up_classes
    base_classes << 'fa-chevron-up'
  end

  def down_classes
    base_classes << 'fa-chevron-down'
  end

  def base_classes
    ['btn', 'btn-default', 'form-control', 'fa']
  end

  def display_up_button?(index, private)
    !(index == 0 || count_type_de_champ(private) < 2)
  end

  def display_down_button?(index, private)
    (index + 1) < count_type_de_champ(private)
  end

  def count_type_de_champ(private)
    if private
      @count_type_de_champ ||= procedure.types_de_champ_private.count
    else
      @count_type_de_champ ||= procedure.types_de_champ.count
    end
  end
end
