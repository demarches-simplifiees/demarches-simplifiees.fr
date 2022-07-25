class CleanupAssignTosFromBetagouv < ActiveRecord::Migration[6.1]
  def up
    super_admin_emails = SuperAdmin.all.pluck(:email)

    super_admin_emails.each do |email|
      user = User.find_by(email: email)
      if user && user.instructeur
        user.instructeur.assign_to.destroy_all
      end
    end
  end
end
