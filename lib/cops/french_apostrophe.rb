# frozen_string_literal: true

if defined?(RuboCop)
  module RuboCop
    module Cop
      module DS
        class FrenchApostrophe < Base
          extend AutoCorrector

          MSG = "Use modifier letter apostrophe ʼ (U+02BC) instead of ' (U+0027) or ' (U+2019) in French text"

          def on_str(node)
            return unless contains_french_with_wrong_apostrophe?(node)

            add_offense(node) do |corrector|
              # Replace ' by ʼ (U+02BC)
              corrected_source = node.source.gsub(/[''']/, 'ʼ')
              corrector.replace(node, corrected_source)
            end
          end

          private

          def contains_french_with_wrong_apostrophe?(node)
            content = node.value

            # check if it is french text with wrong apostrophe
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

            # Exclude code patterns
            return false if looks_like_code?(content)

            french_patterns_with_wrong_apostrophe.any? { |pattern| content.match?(pattern) }
          end

          def looks_like_code?(content)
            code_patterns = [
              /^\s*[\w\.]+\s*!?=\s*/, # assignation
              /^\s*def\s+/,         # method definition
              /^\s*class\s+/,       # class definition
              /^\s*module\s+/,      # module definition
              /^\s*if\s+/,          # condition
              /^\s*unless\s+/,      # negative condition
              /^\s*puts\s+/,        # puts statements
              /puts\s+"/,           # puts with string (anywhere in line)
              /^\s*print\s+/,       # print statements
              /^\s*p\s+/,           # p statements
              /^\s*raise\s+/,       # raise statements
              /^\s*require\s+/,     # require statements
              /^\s*sh\s+/,          # shell commands
              /\$\w+/,              # global variables
              /@\w+/,               # instance variables
              /\w+\(/,              # method call with parentheses
              /\w+\[\w*\]/,         # access to array/hash
              /\w+\.\w+/,           # method call with dot
              /[:]\w+/,             # symbols
              /=>/,                 # hash rocket
              /\{\s*\|/,            # beginning of block
              /^\s*#/,              # comments
              /<%.*%>/,             # ERB tags
              /\\[ntr"']/,          # escaped characters (newlines, tabs, quotes)
              /\\\"/,               # escaped double quotes
              /\\\'/,               # escaped single quotes
              /ENV\[/,              # ENV variables access
              /ActiveRecord::/,     # ActiveRecord references
              /ApplicationRecord\./,# ApplicationRecord method calls
              /\.connection\./,     # database connection calls
              /\.execute\(/,        # SQL execute calls
              /SELECT\s+/i,         # SQL SELECT statements
              /FROM\s+\w+/i,        # SQL FROM clauses
              /WHERE\s+\w+/i,       # SQL WHERE clauses
              /SET\s+LOCAL\s+/i,    # SQL SET LOCAL statements
              /statement_timeout/i, # specific SQL timeout settings
              /\w+::\w+/,           # namespace/constant references
              /!=\s*['"]disabled['"]/,  # specific pattern for disabled checks
              /\.count\.zero\?/,    # method chaining with count and zero?
              /\w+\?\s*$/,          # methods ending with ?
              /&&\s*\w+/,           # logical AND with following code
              /\|\|\s*\w+/,         # logical OR with following code
              /\w+\.\w+\.\w+/,      # method chaining (Class.method.method)
            ]

            code_patterns.any? { |pattern| content.match?(pattern) }
          end
        end
      end
    end
  end
end
