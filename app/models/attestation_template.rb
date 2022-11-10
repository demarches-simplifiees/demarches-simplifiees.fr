# == Schema Information
#
# Table name: attestation_templates
#
#  id           :integer          not null, primary key
#  activated    :boolean
#  body         :text
#  footer       :text
#  title        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :integer
#
class AttestationTemplate < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  include TagsSubstitutionConcern

  has_many :revisions, class_name: 'ProcedureRevision', inverse_of: :attestation_template, dependent: :nullify

  has_one_attached :logo
  has_one_attached :signature

  validates :footer, length: { maximum: 190 }

  FILE_MAX_SIZE = 1.megabytes
  validates :logo, content_type: ['image/png', 'image/jpg', 'image/jpeg'], size: { less_than: FILE_MAX_SIZE }
  validates :signature, content_type: ['image/png', 'image/jpg', 'image/jpeg'], size: { less_than: FILE_MAX_SIZE }

  DOSSIER_STATE = Dossier.states.fetch(:accepte)

  def attestation_for(dossier)
    attestation = Attestation.new(title: replace_tags(title, dossier))
    attestation.pdf.attach(
      io: build_pdf(dossier),
      filename: "attestation-dossier-#{dossier.id}.pdf",
      content_type: 'application/pdf',
      # we don't want to run virus scanner on this file
      metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )
    attestation
  end

  def unspecified_champs_for_dossier(dossier)
    all_champs_with_libelle_index = (dossier.champs + dossier.champs_private).index_by { |champ| "tdc#{champ.stable_id}" }

    used_tags.filter_map do |used_tag|
      corresponding_champ = all_champs_with_libelle_index[used_tag]

      if corresponding_champ && corresponding_champ.blank?
        corresponding_champ
      end
    end
  end

  def dup
    attestation_template = AttestationTemplate.new(title: title, body: body, footer: footer, activated: activated)
    PiecesJustificativesService.clone_attachments(self, attestation_template)
    attestation_template
  end

  def logo_url
    if logo.attached?
      Rails.application.routes.url_helpers.url_for(logo)
    end
  end

  def signature_url
    if signature.attached?
      Rails.application.routes.url_helpers.url_for(signature)
    end
  end

  def render_attributes_for(params = {})
    dossier = params.fetch(:dossier, false)

    {
      created_at: Time.zone.now,
      title: dossier ? replace_tags(title, dossier) : params.fetch(:title, title),
      body: dossier ? replace_tags(body, dossier) : params.fetch(:body, body),
      footer: params.fetch(:footer, footer),
      logo: params.fetch(:logo, logo.attached? ? logo : nil),
      signature: params.fetch(:signature, signature.attached? ? signature : nil)
    }
  end

  def find_or_revise!
    if revisions.size > 1 && procedure.feature_enabled?(:procedure_revisions)
      # If attestation template belongs to more then one revision
      # and procedure has revisions enabled – revise attestation template.
      attestation_template = dup
      attestation_template.save!
      procedure.draft_revision.update!(attestation_template: attestation_template)
      attestation_template
    else
      # If procedure has only one revision or revisions are not supported
      # apply updates directly to the attestation template.
      # If it is a published procedure with revisions disabled,
      # draft and published attestation template will be the same.
      self
    end
  end

  def procedure
    revisions.last&.procedure
  end

  def logo_checksum
    logo.attached? ? logo.checksum : nil
  end

  def signature_checksum
    signature.attached? ? signature.checksum : nil
  end

  def logo_filename
    logo.attached? ? logo.filename : nil
  end

  def signature_filename
    signature.attached? ? signature.filename : nil
  end

  private

  def used_tags
    used_tags_for(title) + used_tags_for(body)
  end

  def build_pdf(dossier)
    attestation = render_attributes_for(dossier: dossier)
    attestation_view = ApplicationController.render(
      template: 'administrateurs/attestation_templates/show',
      formats: :pdf,
      assigns: { attestation: attestation }
    )

    StringIO.new(attestation_view)
  end
end
