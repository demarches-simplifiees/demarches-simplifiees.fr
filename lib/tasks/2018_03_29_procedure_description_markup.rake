require Rails.root.join("app", "helpers", "html_to_string_helper")

namespace :'2018_03_29_procedure_description_markup' do
  task strip: :environment do
    include ActionView::Helpers::TextHelper
    include HtmlToStringHelper

    total = Procedure.count

    Procedure.find_each(batch_size: 100).with_index do |p, i|
      if (i % 100) == 0
        print "Procedure #{i}/#{total}\n"
      end
      p.update_column(:description, html_to_string(p.description))
    end
  end
end
