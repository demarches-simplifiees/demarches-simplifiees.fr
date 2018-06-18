require Rails.root.join("lib", "tasks", "task_helper")
require Rails.root.join("app", "helpers", "html_to_string_helper")

namespace :'2018_03_06_clean_html_textareas' do
  task clean: :environment do
    include ActionView::Helpers::TextHelper
    include HtmlToStringHelper

    rake_puts "PUTS Will migrate champs"

    champs = Champ.joins(:type_de_champ)
      .where(types_de_champ: { type_champ: "textarea" })
      .where("value LIKE '%<%'")

    total = champs.count

    champs.find_each(batch_size: 100).with_index do |c, i|
      if (i % 100) == 0
        rake_puts "Champ #{i}/#{total}\n"
      end
      c.update_column(:value, html_to_string(c.value))
    end
  end
end
