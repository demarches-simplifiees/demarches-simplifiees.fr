module AdminFormulaireHelper
  BASE_CLASSES = ['btn', 'btn-default', 'form-control', 'fa']

  def button_up(procedure, kind, index, url)
    if display_up_button?(index, procedure, kind)
      button(up_classes, "btn_up_#{index}", url)
    end
  end

  def button_down(procedure, kind, index, url)
    if display_down_button?(index, procedure, kind)
      button(down_classes, "btn_down_#{index}", url)
    end
  end

  private

  def button(classes, id, url)
    link_to(
      '',
      url,
      class: classes,
      id: id,
      remote: true,
      method: :post
    )
  end

  def up_classes
    BASE_CLASSES + ['fa-chevron-up']
  end

  def down_classes
    BASE_CLASSES + ['fa-chevron-down']
  end

  def display_up_button?(index, procedure, kind)
    index != 0 && count_type_de_champ(procedure, kind) > 1
  end

  def display_down_button?(index, procedure, kind)
    (index + 1) < count_type_de_champ(procedure, kind)
  end

  def count_type_de_champ(procedure, kind)
    case kind
    when "public"
      @count_type_de_champ_public ||= procedure.types_de_champ.count
    when "private"
      @count_type_de_champ_private ||= procedure.types_de_champ_private.count
    when "piece_justificative"
      @count_type_de_piece_justificative ||= procedure.types_de_piece_justificative.count
    end
  end
end
