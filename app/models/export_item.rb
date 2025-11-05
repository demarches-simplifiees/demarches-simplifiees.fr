# frozen_string_literal: true

class ExportItem
  include TagsSubstitutionConcern
  DOSSIER_STATE = Dossier.states.fetch(:en_construction)
  FORMAT_DATE = "%Y-%m-%d".freeze

  attr_reader :template, :enabled, :stable_id

  def initialize(template:, enabled: true, stable_id: nil)
    @template, @enabled, @stable_id = template, enabled, stable_id
  end

  def self.default(prefix:, enabled: true, stable_id: nil)
    new(template: prefix_dossier_id(prefix), enabled:, stable_id:)
  end

  def self.default_pj(tdc)
    default(prefix: tdc.libelle_as_filename, enabled: false, stable_id: tdc.stable_id)
  end

  def enabled? = enabled

  def template_json = template.to_json

  def template_string = TiptapService.new.to_texts_and_tags(template)

  def path(dossier, attachment: nil, row_index: nil, index: nil)
    used_tags = TiptapService.used_tags_and_libelle_for(template)
    substitutions = tags_substitutions(used_tags, dossier, escape: false, memoize: true)
    substitutions['original-filename'] = attachment.filename.base if attachment

    TiptapService.new.to_texts_and_tags(template, substitutions) + suffix(attachment, row_index, index)
  end

  def ==(other)
    self.class == other.class &&
      template == other.template &&
      enabled == other.enabled &&
      stable_id == other.stable_id
  end

  private

  def self.prefix_dossier_id(prefix)
    {
      type: "doc",
      content: [
        {
          type: "paragraph",
          content: [
            { text: "#{prefix}-", type: "text" },
            { type: "mention", attrs: DOSSIER_ID_TAG.slice(:id, :label) },
          ],
        },
      ],
    }
  end

  def suffix(attachment, row_index, index)
    suffix = ""
    suffix += "-#{add_one_and_pad(row_index)}" if row_index.present?
    suffix += "-#{add_one_and_pad(index)}" if index.present?
    suffix += attachment.filename.extension_with_delimiter if attachment

    suffix
  end

  def add_one_and_pad(number)
    (number + 1).to_s.rjust(2, '0') if number.present?
  end
end
