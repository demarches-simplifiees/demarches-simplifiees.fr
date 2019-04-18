class Timestamp < ApplicationRecord
  has_one_attached :document
  after_create :generate_signature

  private

  def generate_signature
    update!(signature: sign(document_to_sign))
    document.attach(attachement(document_to_sign))
  end

  def document_to_sign
    @document_to_sign ||= DossierOperationLog.order(:created_at)
      .where(created_at: period)
      .documents
      .to_json
  end

  def attachement(document)
    {
      io: StringIO.new(operations_document),
      filename: "#{period.first}-#{period.last}.json",
      content_type: 'application/json',
      identify: false
    }
  end

  # this is just an example code - real code will call a third party API
  def sign(document)
    verifier.generate(document)
  end

  def verifier
    ActiveSupport::MessageVerifier.new(Rails.application.secrets.signing_key)
  end
end
