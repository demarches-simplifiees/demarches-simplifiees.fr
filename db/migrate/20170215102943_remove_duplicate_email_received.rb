class RemoveDuplicateEmailReceived < ActiveRecord::Migration[5.0]
  def change
    all_mails = MailReceived.all
    groupped = all_mails.group_by { |m| m.procedure_id }
    filtered = groupped.reject { |k, v| v.length < 2 }
    filtered.each_value do |duplicate_mails|
      duplicate_mails.pop
      duplicate_mails.each(&:destroy)
    end
  end
end
