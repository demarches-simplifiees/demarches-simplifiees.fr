require Rails.root.join("lib", "tasks", "task_helper")

namespace :after_party do
  # Matches "ne pas répondre", plus some content before and after:
  # - try to remove dashes before the footer
  # - try to remove line-breaks and empty HTML tags before the footer text
  # - matches "Veuillez ne pas répondre" or "Merci de ne pas répondre"
  # - once the footer text is found, extend the match to the end of the body
  FOOTER_REGEXP = /(—|---|-)?( |\r|\n|<br>|<p>|<\/p>|<small>|<\/small>|<b>|<\/b>|&nbsp;)*(Veuillez)?(Merci)?( |\r|\n)*(de)? ne pas répondre(.*)$/m
  # When the footer contains any of these words, it is kept untouched.
  FOOTER_EXCEPTIONS = [
    'PDF',
    '@',
    'Hadrien',
    'Esther',
    'Sicoval',
    'a323',
    'SNC',
    'Polynésie',
    'drac',
    'theplatform'
  ]

  desc 'Deployment task: remove_footer_from_email_templates'
  task remove_footer_from_email_templates: :environment do
    rake_puts "Running deploy task 'remove_footer_from_email_templates'"

    models = [
      Mails::ClosedMail,
      Mails::InitiatedMail,
      Mails::ReceivedMail,
      Mails::RefusedMail,
      Mails::WithoutContinuationMail
    ]

    models.each do |model_class|
      model_class.all.find_each do |template|
        remove_footer(template)
      end
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord.create version: '20181120133842'
  end # task :remove_footer_from_email_templates

  def remove_footer(template)
    matches = template.body.match(FOOTER_REGEXP)
    if matches && FOOTER_EXCEPTIONS.none? { |exception| matches[0].include?(exception) }
      rake_puts "#{template.model_name.to_s} \##{template.id}: removing footer"
      template.update(body: matches.pre_match)
    end
  end
end # namespace :after_party
