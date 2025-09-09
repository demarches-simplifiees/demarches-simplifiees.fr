# frozen_string_literal: true

class AttestationRefusTemplate < ApplicationRecord
  include AttestationTemplateConcern

  belongs_to :procedure, inverse_of: :attestation_refus_template

  validates :title, tags: true, if: -> { procedure.present? && version == 1 }
  validates :body, tags: true, if: -> { procedure.present? && version == 1 }
  validates :json_body, tags: true, if: -> { procedure.present? && version == 2 }

  DOSSIER_STATE = Dossier.states.fetch(:refuse)

  TIPTAP_BODY_DEFAULT = {
    "type" => "doc",
    "content" => [
      {
        "type" => "header",
        "content" => [
          {
            "type" => "headerColumn",
                      "content" => [
                        {
                          "type" => "paragraph",
                          "attrs" => { "textAlign" => "left" },
                          "content" => [{ "type" => "mention", "attrs" => { "id" => "dossier_service_name", "label" => "nom du service" } }]
                        }
                      ]
          },
          {
            "type" => "headerColumn",
            "content" => [
              {
                "type" => "paragraph",
                          "attrs" => { "textAlign" => "left" },
                          "content" => [
                            { "text" => "Fait le ", "type" => "text" },
                            { "type" => "mention", "attrs" => { "id" => "dossier_processed_at", "label" => "date de décision" } }
                          ]
              }
            ]
          }
        ]
      },
      { "type" => "title", "attrs" => { "textAlign" => "center" }, "content" => [{ "text" => "Notification de refus", "type" => "text" }] },
      {
        "type" => "paragraph",
        "attrs" => { "textAlign" => "left" },
        "content" => [
          {
            "text" => "Nous avons le regret de vous informer que votre demande n° ",
            "type" => "text"
          },
          { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } },
          {
            "text" => " a été refusée pour le motif suivant :",
            "type" => "text"
          }
        ]
      },
      {
        "type" => "paragraph",
        "attrs" => { "textAlign" => "left" },
        "content" => [
          { "type" => "mention", "attrs" => { "id" => "dossier_motivation", "label" => "motivation de la décision" } }
        ]
      }
    ]
  }.freeze

  private

  def template_path_v1
    'administrateurs/attestation_refus_templates/show'
  end

  def template_path_v2
    '/administrateurs/attestation_refus_template_v2s/show'
  end
end