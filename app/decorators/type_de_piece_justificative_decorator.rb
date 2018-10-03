class TypeDePieceJustificativeDecorator < Draper::Decorator
  delegate_all
  def button_up(params)
    if display_up_button?(params[:index])
      h.link_to '', params[:url], class: up_classes, id: "btn_up_#{params[:index]}", remote: true, method: :post
    end
  end

  def button_down(params)
    if display_down_button?(params[:index])
      h.link_to '', params[:url], class: down_classes, id: "btn_down_#{params[:index]}", remote: true, method: :post
    end
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

  def display_up_button?(index)
    !(index == 0 || count_type_de_piece_justificative < 2)
  end

  def display_down_button?(index)
    (index + 1) < count_type_de_piece_justificative
  end

  def count_type_de_piece_justificative
    @count_type_de_piece_justificative ||= procedure.types_de_piece_justificative.count
  end
end
