class BillSignature < ApplicationRecord
  has_many :dossier_operation_logs

  has_one_attached :serialized
  has_one_attached :signature

  validate :check_bill_digest
  validate :check_serialized_bill_contents
  validate :check_signature_contents

  def self.build_with_operations(operations, day)
    bill = new(dossier_operation_logs: operations)

    bill.serialize_operations(day)

    bill
  end

  def serialize_operations(day)
    serialized.attach(
      io: StringIO.new(operations_bill_json),
      filename: "demarches-simplifiees-operations-#{day.to_date.iso8601}.json",
      content_type: 'application/json',
      metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )

    self.digest = operations_bill_digest
  end

  def operations_bill
    dossier_operation_logs.map { |op| [op.id.to_s, op.digest] }.to_h
  end

  def operations_bill_json
    operations_bill.to_json
  end

  def operations_bill_digest
    Digest::SHA256.hexdigest(operations_bill_json)
  end

  def set_signature(signature, day)
    signature.attach(
      io: StringIO.new(signature),
      filename: "demarches-simplifiees-signature-#{day.to_date.iso8601}.der",
      content_type: 'application/x-x509-ca-cert'
    )
  end

  # Validations
  def check_bill_digest
    if digest != operations_bill_digest
      errors.add(:digest)
    end
  end

  def check_serialized_bill_contents
    if !serialized.attached?
      errors.add(:serialized, :blank)
      return
    end

    if JSON.parse(read_serialized) != operations_bill
      errors.add(:serialized)
    end
  end

  def check_signature_contents
    if !signature.attached?
      errors.add(:signature, :blank)
      return
    end

    timestamp_signature_date = ASN1::Timestamp.signature_time(read_signature)
    if timestamp_signature_date > Time.zone.now
      errors.add(:signature, :invalid_date)
    end

    timestamp_signed_digest = ASN1::Timestamp.signed_digest(read_signature)
    if timestamp_signed_digest != digest
      errors.add(:signature)
    end
  end

  def read_signature
    if attachment_changes['signature']
      io = attachment_changes['signature'].attachable[:io]
      io.read if io.present?
    elsif signature.attached?
      signature.download
    end
  end

  def read_serialized
    if attachment_changes['serialized']
      io = attachment_changes['serialized'].attachable[:io]
      io.read if io.present?
    elsif serialized.attached?
      serialized.download
    end
  end
end
