# frozen_string_literal: true

if defined?(RuboCop)
  module RuboCop
    module Cop
      module DS
        class ApplicationName < Base
          MSG = "Avoid hardcoding `demarche.numerique.gouv.fr`. Instead use a dedicated environnement variable."
          def on_str(node)
            return unless node.source.include?('demarche.numerique.gouv.fr')

            add_offense(node)
          end
        end
      end
    end
  end
end
