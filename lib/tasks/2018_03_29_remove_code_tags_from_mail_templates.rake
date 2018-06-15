require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2018_03_29_remove_code_tags_from_mail_templates' do
  task clean: :environment do
    remove_code_tag_from_body(Mails::ClosedMail)
    remove_code_tag_from_body(Mails::InitiatedMail)
    remove_code_tag_from_body(Mails::ReceivedMail)
    remove_code_tag_from_body(Mails::RefusedMail)
    remove_code_tag_from_body(Mails::WithoutContinuationMail)
  end

  def remove_code_tag_from_body(model_class)
    mails = model_class.where("body LIKE ?", "%<code>%")
    rake_puts "#{mails.count} #{model_class.name} to clean"
    mails.each do |m|
      rake_puts "cleaning #{model_class.name} ##{m.id}"
      m.update(body: m.body.gsub("<code>", "").gsub("</code>", ""))
    end
  end
end
