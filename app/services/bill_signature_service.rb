class BillSignatureService
  def self.grouped_unsigned_operation_until(date)
    unsigned_operations = DossierOperationLog
      .where(bill_signature: nil)
      .where('executed_at < ?', date)

    unsigned_operations.group_by { |e| e.executed_at.to_date }
  end

  def self.sign_operations(operations, day)
    bill = BillSignature.build_with_operations(operations, day)
    signature = Universign::API.timestamp(bill.digest)
    bill.set_signature(signature, day)
    bill.save!
  end
end
