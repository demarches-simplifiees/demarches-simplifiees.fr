# frozen_string_literal: true

module LLM
  class HeaderComponent < ApplicationComponent
    attr_reader :llm_rule_suggestion
    def initialize(llm_rule_suggestion:)
      @llm_rule_suggestion = llm_rule_suggestion
    end

    def last_suggestion_created_at_tag
      if llm_rule_suggestion.persisted?
        timestamp = I18n.l(llm_rule_suggestion.created_at, format: :llm_stepper_last_refresh)
        tag.p(I18n.t('llm.stepper_component.last_refresh', timestamp:), class: 'fr-hint-text')
      else
        tag.p(I18n.t('llm.stepper_component.no_suggestion_yet'), class: 'fr-hint-text')
      end
    end

    def accordion_id
      @accordion_id ||= "llm-accordion-#{SecureRandom.hex(4)}"
    end

    def call
      tag.div do
        safe_join([
          last_suggestion_created_at_tag,
          tag.section(class: 'fr-accordion fr-mt-2w fr-mb-3w') do
            tag.h3(class: 'fr-accordion__title') do
              tag.button(
                'Comment fonctionne ce module d\'amélioration ?',
                type: :button,
                class: 'fr-accordion__btn',
                'aria-controls' => accordion_id,
                'aria-expanded' => 'false'
              )
            end +
            tag.div(class: 'fr-collapse', id: accordion_id) do
              tag.div(class: 'fr-mt-1w') do
                safe_join([
                  tag.p('Ce module est une assistance à la bonne création de votre formulaire.', class: 'fr-mb-0'),
                  tag.p('Nous analysons l\'intégralité des champs du formulaire afin de suggérer automatiquement des améliorations.', class: 'fr-mb-0'),
                  tag.p('Les suggestions d\'amélioration peuvent porter sur :', class: 'fr-mb-0'),
                  tag.ul do
                    safe_join([
                      tag.li(safe_join(['Les ', tag.strong('libellés des champs'), ' : mise à jour des libellés de champs détectés comme trop longs, en majuscules ou difficiles à comprendre.'])),
                      tag.li(safe_join(['La ', tag.strong('structure du formulaire'), ' : amélioration de la structure du formulaire en réorganisant les champs et en ajoutant des sections.'])),
                      tag.li(safe_join(['La ', tag.strong('demande unique d\'information ("Dites-le nous une fois")'), ' : suppression des champs détectés comme redondants ou en doublon.'])),
                      tag.li(safe_join(['La ', tag.strong('bonne utilisation des types de champs'), ' : transformation de certains champs en d\'autres types de champs, plus adaptés au regard de l\'information attendue.'])),
                    ])
                  end,
                  tag.p('Vous êtes libre de choisir les suggestions que vous souhaitez appliquer.'),
                ])
              end
            end
          end,
        ])
      end
    end
  end
end
