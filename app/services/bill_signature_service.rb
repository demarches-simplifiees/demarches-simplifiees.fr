# frozen_string_literal: true

class BillSignatureService
  def self.sign_operations(operations, day)
    return unless Certigna::API.enabled?
    bill = BillSignature.build_with_operations(operations, day)
    signature = Certigna::API.timestamp(bill.digest)
    bill.set_signature(signature, day)
    bill.save!

    ensure_valid_signature(bill.reload)
  rescue => error
    operations.each { |o| o.update(bill_signature: nil) }
    bill&.destroy
    raise error
  end

  def self.ensure_valid_signature(bill)
    Dir.mktmpdir do |dir|
      operations_path = File.join(dir, 'operations')
      File.write(operations_path, bill.serialized.download, mode: 'wb')

      signature_path = File.join(dir, 'signature')
      File.write(signature_path, bill.signature.download, mode: 'wb')

      authorities_path = Rails.application.config.root.join('app', 'lib', 'certigna', 'authorities.crt').to_s

      verify_cmd = "openssl ts -verify -CAfile #{authorities_path.shellescape} -data #{operations_path.shellescape} -in #{signature_path.shellescape} -token_in"

      openssl_errors = nil
      openssl_output = nil

      process_status = Open3.popen3(verify_cmd) do |_stdin, stdout, stderr, wait_thr|
        openssl_errors = stderr.read
        openssl_output = stdout.read
        wait_thr.value
      end

      if !process_status.success? || openssl_output&.strip != 'Verification: OK'
        raise StandardError, "openssl verification failed: #{openssl_errors}"
      end
    end
  end
end
