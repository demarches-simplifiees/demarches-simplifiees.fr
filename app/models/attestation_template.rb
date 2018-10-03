class AttestationTemplate < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  include TagsSubstitutionConcern

  belongs_to :procedure

  mount_uploader :logo, AttestationTemplateLogoUploader
  mount_uploader :signature, AttestationTemplateSignatureUploader

  validate :logo_signature_file_size
  validates :footer, length: { maximum: 190 }

  FILE_MAX_SIZE_IN_MB = 0.5
  DOSSIER_STATE = Dossier.states.fetch(:accepte)

  def attestation_for(dossier)
    Attestation.new(title: replace_tags(title, dossier), pdf: build_pdf(dossier))
  end

  def unspecified_champs_for_dossier(dossier)
    all_champs_with_libelle_index = (dossier.champs + dossier.champs_private)
      .reduce({}) do |acc, champ|
        acc[champ.libelle] = champ
        acc
      end

    used_tags.map do |used_tag|
      corresponding_champ = all_champs_with_libelle_index[used_tag]

      if corresponding_champ && corresponding_champ.value.blank?
        corresponding_champ
      end
    end.compact
  end

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

  def used_tags
    delimiters_regex = /--(?<capture>((?!--).)*)--/

    # We can't use flat_map as scan will return 3 levels of array,
    # using flat_map would give us 2, whereas flatten will
    # give us 1, which is what we want
    [title, body]
      .map { |str| str.scan(delimiters_regex) }
      .flatten
  end

  def logo_signature_file_size
    [:logo, :signature]
      .select { |file_name| send(file_name).present? }
      .each { |file_name| file_size_check(file_name) }
  end

  def file_size_check(file_name)
    if send(file_name).file.size.to_f > FILE_MAX_SIZE_IN_MB.megabyte.to_f
      errors.add(file_name, " : vous ne pouvez pas charger une image de plus de #{number_with_delimiter(FILE_MAX_SIZE_IN_MB, locale: :fr)} Mo")
    end
  end

  def build_pdf(dossier)
    action_view = ActionView::Base.new(ActionController::Base.view_paths,
      logo: logo,
      title: replace_tags(title, dossier),
      body: replace_tags(body, dossier),
      signature: signature,
      footer: footer,
      created_at: Time.now)

    attestation_view = action_view.render(file: 'admin/attestation_templates/show',
      formats: [:pdf])

    view_to_memory_file(attestation_view)
  end

  def view_to_memory_file(view)
    pdf = StringIO.new(view)

    def pdf.original_filename
      'attestation'
    end

    pdf
  end
end
