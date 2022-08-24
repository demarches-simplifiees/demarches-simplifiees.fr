class ReaddSuperAdminToTheirProcedureWithoutInstructeur < ActiveRecord::Migration[6.1]
  def change
    super_admin_emails = SuperAdmin.all.pluck(:email)
    # we want to re-assign each super admin being an admin of a procedure
    # to every procedure that lost all instructeur
    # so we cache procedure without instructeur first
    procedure_without_instructeur_ids = []

    super_admin_emails.each do |email|
      user = User.find_by(email: email)
      if user&.administrateur.nil?
        next
      end
      user.administrateur.procedures.each do |procedure|
        if procedure.instructeurs.count == 0
          procedure_without_instructeur_ids << procedure.id
        end
      end
    end
    procedure_without_instructeur_ids = procedure_without_instructeur_ids.uniq
    puts "procedure without instructeur: #{procedure_without_instructeur_ids.inspect}"
    super_admin_emails.each do |email|
      user = User.find_by(email: email)
      if user&.administrateur.nil?
        next
      end
      user.administrateur.procedures.each do |procedure|
        if procedure_without_instructeur_ids.include?(procedure.id)
          puts "add: #{user.email} to #{procedure.id}/#{procedure.libelle}"
          procedure.groupe_instructeurs.each do |groupe_instructeur|
            groupe_instructeur.add(user.instructeur)
          end
        end
      end
    end
  end
end
