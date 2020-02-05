if defined?(RuboCop)
  module RuboCop
    module Cop
      module DS
        class Unscoped < Cop
          MSG = "Avoid using `unscoped`. Instead unscope specific clauses by using `unscope(where: :attribute)`."

          def_node_matcher :unscoped?, <<-END
            (send _ :unscoped)
          END

          def on_send(node)
            return unless unscoped?(node)
            add_offense(node)
          end
        end
      end
    end
  end
end
