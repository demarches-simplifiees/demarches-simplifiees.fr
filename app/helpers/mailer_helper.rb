# frozen_string_literal: true

module MailerHelper
  def vertical_margin(height)
    render 'shared/mailer_vertical_margin', height: height
  end

  def round_button(text, url, variant)
    render 'shared/mailer_round_button', text: text, url: url, theme: theme(variant)
  end

  private

  def theme(variant)
    case variant
    when :primary
      { color: white, bg_color: blue, border_color: blue }
    when :secondary
      { color: blue, bg_color: white, border_color: blue }
    end
  end

  def blue
    '#000091'
  end

  def white
    '#FFFFFF'
  end
end
