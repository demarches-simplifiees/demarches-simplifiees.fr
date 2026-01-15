# frozen_string_literal: true

class DossierSubmittedMessage < ApplicationRecord
  has_many :revisions, class_name: 'ProcedureRevision', inverse_of: :dossier_submitted_message, dependent: :nullify

  def tiptap_body
    json_body&.to_json
  end

  def tiptap_body=(json)
    self.json_body = JSON.parse(json)
  end

  def tiptap_body_or_default
    if json_body.present?
      json_body.to_json
    elsif message_on_submit_by_usager.present?
      plain_text_to_tiptap_json(message_on_submit_by_usager).to_json
    else
      default_tiptap_json.to_json
    end
  end

  def body_as_html
    return nil if json_body.blank?
    TiptapService.new.to_html(json_body.deep_symbolize_keys)
  end

  def has_tiptap_content?
    json_body.present?
  end

  private

  def plain_text_to_tiptap_json(text)
    paragraphs = text.to_s.split(/\n\n+/).map do |para|
      {
        "type" => "paragraph",
        "content" => [{ "type" => "text", "text" => para.tr("\n", ' ').strip }],
      }
    end.reject { |p| p["content"].first["text"].blank? }
    paragraphs = [{ "type" => "paragraph" }] if paragraphs.empty?
    { "type" => "doc", "content" => paragraphs }
  end

  def default_tiptap_json
    { "type" => "doc", "content" => [{ "type" => "paragraph" }] }
  end
end
