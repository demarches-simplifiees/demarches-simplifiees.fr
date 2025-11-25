# frozen_string_literal: true

if defined?(RuboCop)
  module RuboCop
    module Cop
      module DS
        class AdresseElectronique < Base
          MSG = 'Use "adresse électronique" instead of "adresse email", "adresse mail", or "adresse e-mail"'

          def on_str(node)
            return unless node.source.match?(/adresse(s)?\s+(email|mail|e-mail)/i)

            add_offense(node, message: MSG)
          end
        end
      end
    end
  end
end
