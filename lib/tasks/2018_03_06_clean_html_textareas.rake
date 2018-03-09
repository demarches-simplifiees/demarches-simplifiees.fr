require Rails.root.join("app", "helpers", "html_to_string_helper")

namespace :'2018_03_06_clean_html_textareas' do
  task clean: :environment do
    include ActionView::Helpers::TextHelper
    include HtmlToStringHelper

    types_de_champ = TypeDeChamp.joins(:champ)
      .where(type_champ: "textarea")
      .where("champs.value LIKE '%<%'")

    types_de_champ.find_each do |tdc|
      tdc.champ.each { |c| c.update_column(:value, html_to_string(c.value)) }
    end
  end
end
