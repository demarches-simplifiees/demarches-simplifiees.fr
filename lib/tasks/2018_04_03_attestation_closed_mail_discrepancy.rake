namespace :'2018_04_03_attestation_closed_mail_discrepancy' do
  task mail_adminstrators: :environment do
    Administrateur.includes(:procedures).find_each(batch_size: 10) do |admin|
      procedures = admin.procedures.where(archived_at: nil).select { |p| p.closed_mail_template_attestation_inconsistency_state == :missing_tag }
      if procedures.any?
        # Use `deliver_now` because the delayed job cannot find the `Mailers::AttestationClosedMailDiscrepancyMaile` class in production
        Mailers::AttestationClosedMailDiscrepancyMailer.missing_attestation_tag_email(admin, procedures).deliver_now!
        print "#{admin.email}\n"
      end
    end
  end
end
