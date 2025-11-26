# frozen_string_literal: true

if defined?(RuboCop)
  module RuboCop
    module Cop
      module DS
        class FrenchApostrophe < Base
          extend AutoCorrector

          MSG = "Use modifier letter apostrophe ʼ (U+02BC) instead of ' (U+0027) or ' (U+2019) in French text"

          # Cibler uniquement les nœuds de chaînes
          def on_str(node)
            return unless contains_french_with_wrong_apostrophe?(node)

            add_offense(node) do |corrector|
              # Remplacer ' et ' par ʼ (U+02BC)
              corrected_source = node.source.gsub(/[''']/, 'ʼ')
              corrector.replace(node, corrected_source)
            end
          end

          private

          def contains_french_with_wrong_apostrophe?(node)
            content = node.value # Le contenu de la string sans les quotes

            # Vérifier si c'est du texte français avec mauvaise apostrophe
            french_patterns_with_wrong_apostrophe = [
              /l['']/, # l'adresse -> lʼadresse
              /d['']/, # d'accord -> dʼaccord
              /n['']/, # n'est -> nʼest
              /j['']/, # j'ai -> jʼai
              /m['']/, # m'inscrire -> mʼinscrire
              /s['']/, # s'inscrire -> sʼinscrire
              /c['']/, # c'est -> cʼest
              /qu['']/, # qu'il -> quʼil
              /aujourd['']/, # aujourd'hui -> aujourdʼhui
              /quelqu['']/, # quelqu'un -> quelquʼun
            ]

            # Exclure les patterns qui ressemblent à du code
            return false if looks_like_code?(content)

            french_patterns_with_wrong_apostrophe.any? { |pattern| content.match?(pattern) }
          end

          def looks_like_code?(content)
            code_patterns = [
              /^\s*[\w\.]+\s*=\s*/, # assignation
              /^\s*def\s+/,         # définition de méthode
              /^\s*class\s+/,       # définition de classe
              /^\s*module\s+/,      # définition de module
              /^\s*if\s+/,          # condition
              /^\s*unless\s+/,      # condition négative
              /\$\w+/,              # variables globales
              /@\w+/,               # variables d'instance
              /\w+\(/,              # appels de méthode avec parenthèses
              /\w+\[\w*\]/,         # accès tableau/hash
              /\w+\.\w+/,           # appels de méthode avec point
              /[:]\w+/,             # symboles
              /=>/,                 # hash rocket
              /\{\s*\|/,            # début de bloc
              /^\s*#/,              # commentaires
              /<%.*%>/,             # ERB tags
            ]

            code_patterns.any? { |pattern| content.match?(pattern) }
          end
        end
      end
    end
  end
end
