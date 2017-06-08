class AttestationTemplate < ApplicationRecord
  include ActionView::Helpers::NumberHelper

  belongs_to :procedure

  mount_uploader :logo, AttestationTemplateImageUploader
  mount_uploader :signature, AttestationTemplateImageUploader

  validate :logo_signature_file_size

  FILE_MAX_SIZE_IN_MB = 0.5

  def dup
    result = AttestationTemplate.new(title: title, body: body, footer: footer, activated: activated)

    if logo.present?
      CopyCarrierwaveFile::CopyFileService.new(self, result, :logo).set_file
    end

    if signature.present?
      CopyCarrierwaveFile::CopyFileService.new(self, result, :signature).set_file
    end

    result
  end

  private

  def logo_signature_file_size
    %i[logo signature]
      .select { |file_name| send(file_name).present? }
      .each { |file_name| file_size_check(file_name) }
  end

  def file_size_check(file_name)
    if send(file_name).file.size.to_f > FILE_MAX_SIZE_IN_MB.megabyte.to_f
      errors.add(file_name, " : vous ne pouvez pas charger une image de plus de #{number_with_delimiter(FILE_MAX_SIZE_IN_MB, locale: :fr)} Mo")
    end
  end
end
