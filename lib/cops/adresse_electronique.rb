# frozen_string_literal: true

if defined?(RuboCop)
  module RuboCop
    module Cop
      module DS
        class AdresseElectronique < Base
          MSG = 'Use "adresse électronique" instead of "adresse email", "adresse mail", or "adresse e-mail"'

          def on_new_investigation
            return unless relevant_file?

            content = processed_source.raw_source
            return unless content.match?(/adresse\s+(email|mail|e-mail)/i)

            add_offense(nil, message: MSG)
          end

          private

          def relevant_file?
            file_path = processed_source.file_path

            %w[.haml .erb .html .yml .yaml].include?(File.extname(file_path))
          end
        end
      end
    end
  end
end
