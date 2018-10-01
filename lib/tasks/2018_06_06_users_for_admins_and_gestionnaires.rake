require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2018_06_06_users_for_admins_and_gestionnaires' do
  task preactivate: :environment do
    preactivate_users(Gestionnaire, 'accompagnateur') { |g| g.reset_password_token.nil? }
    preactivate_users(Administrateur, &:active?)
  end

  def preactivate_users(model, role_name = nil, &block)
    table_name = model.table_name
    role_name ||= table_name.singularize

    already_activated = model
      .joins("INNER JOIN users ON #{table_name}.email = users.email")
      .where(users: { confirmed_at: nil })
      .to_a
      .select(&block)

    rake_puts "Sending emails to #{already_activated.count} #{table_name} that were already confirmed"

    already_activated.each { |m| PreactivateUsersMailer.reinvite(m, role_name).deliver_later }

    count =
      User
        .joins("INNER JOIN #{table_name} ON #{table_name}.email = users.email")
        .where(confirmed_at: nil)
        .update_all(confirmed_at: DateTime.now)

    rake_puts "Fixed #{count} #{table_name} with unconfirmed user"
  end
end
