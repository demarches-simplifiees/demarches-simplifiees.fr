# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: delete_roles_without_users'
  task delete_roles_without_users: :environment do
    rake_puts "Running deploy task 'delete_roles_without_users'"

    # For now, deleting a user with any role (administrateur, instructeur or expert) is forbidden.
    #
    # However, in the past, some users with roles may have been deleted – without the corresponding roles being
    # also removed. This creates invalid roles, referenced by no users (but still referenced by other records).
    #
    # To prevent this situation, future database migrations will add more constraints on roles.
    # But before adding constraints, we need to clean up any dangling role that may exist.

    # Helper method
    def raise_no_admin_error(service)
      message = <<~EOE
        Error while re-assigning Service \##{service.id} to another Administrateur.

        We tried to re-assign the Service \##{service.id} to another Administrateur,
        but none of the Procedures (#{service.procedures.pluck(:id)}) attached to this Service had other Administrateurs
        to assign the service to.

        Please fix the Service \##{service.id} manually (by assigning it to any valid administrator, for instance the
        first one in your database), then run this task again.
      EOE
      raise RuntimeError, message
    end

    #
    # Delete dangling administrateurs (administrateurs without an existing user)
    #

    rake_puts "\nFinding dangling administrateurs…"
    dangling_administrateurs = Administrateur.where.missing(:user)
    rake_puts "#{dangling_administrateurs.count} dangling administrateurs found."

    if dangling_administrateurs.any?
      # An administrateur can't be removed if it has services.
      # For those services:
      #   - delete services not referenced by any procedure
      #   - re-assign the other services to the first admin of a procedure using this service
      rake_puts "  Removing or re-assigning their services…"
      dangling_services = dangling_administrateurs.map(&:services).flatten
      services_with_procedures, services_without_procedures = dangling_services.partition { |s| s.procedures.any? }
      services_with_procedures.each do |service|
        other_admins = service.procedures.flat_map(&:administrateurs).excluding(service.administrateur)
        raise_no_admin_error(service) if other_admins.empty?
        service.update!(administrateur: other_admins.first)
      end
      services_without_procedures.each(&:destroy)
      rake_puts "  #{services_with_procedures.length} services re-assigned, #{services_without_procedures.length} services destroyed."

      # Now we can destroy dangling administrateurs
      rake_puts "  Destroying #{dangling_administrateurs.count} dangling administrateurs…"
      deleted_records = dangling_administrateurs.destroy_all
      rake_puts "  #{deleted_records.length} dangling administrateurs destroyed."
    end

    #
    # Delete dangling instructeurs (instructeurs without an existing user)
    #
    rake_puts "\nFinding dangling instructeurs…"
    deleted_records = Instructeur.where.missing(:user).destroy_all
    rake_puts "#{deleted_records.length} dangling instructeurs destroyed."

    #
    # Delete dangling experts (experts without an existing user)
    #
    rake_puts "\nFinding dangling experts…"
    deleted_records = Expert.where.missing(:user).destroy_all
    rake_puts "#{deleted_records.length} dangling experts destroyed."

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
