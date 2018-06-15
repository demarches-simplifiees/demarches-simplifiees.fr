class Champs::TextareaChamp < Champs::TextChamp
  private

  def value_for_export
    ActionView::Base.full_sanitizer.sanitize(value)
  end
end
