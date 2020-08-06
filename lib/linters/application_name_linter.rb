if defined?(HamlLint)
  module HamlLint
    class Linter::ApplicationNameLinter < Linter
      include LinterRegistry

      FORBIDDEN = 'demarches-simplifiees.fr'
      REPLACEMENT = "APPLICATION_NAME"
      MSG = 'Hardcoding %s is forbidden, use %s instead'

      def visit_tag(node)
        check(node)
      end

      def visit_script(node)
        check(node)
      end

      def visit_silent_script(node)
        check(node)
      end

      def visit_plain(node)
        check(node)
      end

      def visit_comment(node)
        check(node)
      end

      def visit_haml_comment(node)
        check(node)
      end

      def check(node)
        line = line_text_for_node(node)
        if line.downcase.include?(FORBIDDEN)
          record_lint(node, format(MSG, FORBIDDEN, REPLACEMENT))
        end
      end

      private

      def line_text_for_node(node)
        document.source_lines[node.line - 1]
      end
    end
  end
end
