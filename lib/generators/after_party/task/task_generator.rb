# frozen_string_literal: true

require 'rails/generators'

Rails.application.config.after_initialize do
  module AfterParty
    module Generators
      class TaskGenerator
        prepend Module.new {
          def invoke_all
            warn "[DEPRECATION] 'after_party:task' is deprecated. Use 'rails generate maintenance_tasks:task #{name}' instead."
          end
        }
      end
    end
  end
end
