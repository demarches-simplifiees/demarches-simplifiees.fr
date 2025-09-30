# frozen_string_literal: true

if defined?(RuboCop)
  module RuboCop
    module Cop
      module RSpec
        # This cop detects consecutive `it` blocks in RSpec specs.
        # Consecutive `it` blocks unnecessarily re-run the entire setup (before, let, etc.)
        # instead of grouping related assertions in a single block.
        #
        # By default (OnlyWithoutDescription: true), only flags consecutive `it` blocks
        # without descriptions or with empty string descriptions.
        #
        # @example OnlyWithoutDescription: true (default)
        #   # bad - consecutive it blocks without description
        #   describe 'User' do
        #     let(:user) { User.create(name: 'John') }
        #
        #     it { expect(user.name).to eq('John') }
        #     it { expect(user).to be_valid }
        #   end
        #
        #   # good - group related assertions
        #   describe 'User' do
        #     let(:user) { User.create(name: 'John') }
        #
        #     it do
        #       expect(user.name).to eq('John')
        #       expect(user).to be_valid
        #     end
        #   end
        #
        #   # good - it blocks with descriptions are not flagged
        #   describe 'User' do
        #     let(:user) { User.create(name: 'John') }
        #
        #     it 'has a name' do
        #       expect(user.name).to eq('John')
        #     end
        #
        #     it 'is valid' do
        #       expect(user).to be_valid
        #     end
        #   end
        #
        #   # good - using subject (may have side-effects)
        #   describe 'User' do
        #     subject { User.create(name: 'John') }
        #
        #     it { expect(subject.name).to eq('John') }
        #     it { expect(subject).to be_valid }
        #   end
        #
        # @example OnlyWithoutDescription: false
        #   # bad - consecutive it blocks even with descriptions
        #   describe 'User' do
        #     let(:user) { User.create(name: 'John') }
        #
        #     it 'has a name' do
        #       expect(user.name).to eq('John')
        #     end
        #
        #     it 'is valid' do
        #       expect(user).to be_valid
        #     end
        #   end
        #
        #   # good - separate with context or describe
        #   describe 'User' do
        #     let(:user) { User.create(name: 'John') }
        #
        #     it 'has a name' do
        #       expect(user.name).to eq('John')
        #     end
        #
        #     context 'when validating' do
        #       it 'is valid' do
        #         expect(user).to be_valid
        #       end
        #     end
        #   end
        #
        # Autocorrection merges consecutive blocks and combines descriptions
        # when OnlyWithoutDescription is false.
        class ConsecutiveItBlocks < Base
          MSG = 'Avoid consecutive `it` blocks. ' \
                'Group related assertions in a single `it` ' \
                'or separate them with `context` or `describe`.'

          RESTRICT_ON_SEND = [:it].freeze

          def on_send(node)
            return unless node.method?(:it)
            return unless node.block_node
            return if only_without_description? && has_description?(node)
            return if has_expect_with_block?(node.block_node)

            next_sibling = find_next_it_sibling(node.parent)
            return unless next_sibling&.block_type?
            return unless next_sibling.send_node.method?(:it)
            return if only_without_description? && has_description?(next_sibling.send_node)
            return if has_expect_with_block?(next_sibling)

            add_offense(next_sibling.send_node)
          end

          private

          def only_without_description?
            cop_config.fetch('OnlyWithoutDescription', true)
          end

          def has_description?(node)
            first_arg = node.first_argument
            return false unless first_arg&.str_type?
            !first_arg.str_content.empty?
          end

          def has_expect_with_block?(block_node)
            return false unless block_node&.body

            # Check for expect { } pattern (expect with a block argument)
            block_node.each_descendant(:block) do |inner_block|
              next unless inner_block.send_node&.method?(:expect)
              return true
            end

            false
          end

          def find_next_it_sibling(node)
            return nil unless node

            siblings = node.parent&.children || []
            current_index = siblings.index(node)
            return nil unless current_index

            next_sibling = siblings[current_index + 1]
            return nil unless next_sibling&.is_a?(RuboCop::AST::Node)

            # Check if there are comments between the two nodes
            current_end_line = node.last_line
            next_start_line = next_sibling.first_line

            # If there's more than one line between nodes, check for comments
            if next_start_line - current_end_line > 1
              processed_source.comments.any? do |comment|
                comment_line = comment.location.line
                comment_line > current_end_line && comment_line < next_start_line
              end ? nil : next_sibling
            else
              next_sibling
            end
          end
        end
      end
    end
  end
end
