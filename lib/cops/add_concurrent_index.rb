# frozen_string_literal: true

# Copyright (c) 2011-present GitLab B.V.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

if defined?(RuboCop)
  module RuboCop
    module Cop
      module DS
        # Cop that checks if `add_concurrent_index` is used with `up`/`down` methods
        # and not `change`.
        class AddConcurrentIndex < Base
          MSG = '`add_concurrent_index` is not reversible so you must manually define ' \
            'the `up` and `down` methods in your migration class, using `remove_index` in `down`'

          def on_send(node)
            dirname = File.dirname(node.location.expression.source_buffer.name)
            return unless dirname.end_with?('db/migrate')

            name = node.children[1]

            return unless name == :add_concurrent_index

            node.each_ancestor(:def) do |def_node|
              next unless method_name(def_node) == :change

              add_offense(def_node, location: :name)
            end
          end

          def method_name(node)
            node.children.first
          end
        end
      end
    end
  end
end
