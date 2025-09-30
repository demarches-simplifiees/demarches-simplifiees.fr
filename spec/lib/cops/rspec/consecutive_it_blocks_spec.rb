# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../lib/cops/rspec/consecutive_it_blocks'

RSpec.describe RuboCop::Cop::RSpec::ConsecutiveItBlocks do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config.new('RSpec/ConsecutiveItBlocks' => {})
  end

  context 'with OnlyWithoutDescription: true (default)' do
    it 'registers an offense for consecutive it blocks without description' do
      expect_offense(<<~RUBY)
        describe 'User' do
          it { expect(user.name).to eq('John') }
          it { expect(user).to be_valid }
          ^^ Avoid consecutive `it` blocks. Group related assertions in a single `it` or separate them with `context` or `describe`.
        end
      RUBY
    end

    it 'registers an offense for multiple consecutive it blocks' do
      expect_offense(<<~RUBY)
        describe 'User' do
          it { expect(user.name).to eq('John') }
          it { expect(user).to be_valid }
          ^^ Avoid consecutive `it` blocks. Group related assertions in a single `it` or separate them with `context` or `describe`.
          it { expect(user.active?).to be(true) }
          ^^ Avoid consecutive `it` blocks. Group related assertions in a single `it` or separate them with `context` or `describe`.
        end
      RUBY
    end

    it 'does not register an offense for it blocks with descriptions' do
      expect_no_offenses(<<~RUBY)
        describe 'User' do
          it 'has a name' do
            expect(user.name).to eq('John')
          end

          it 'is valid' do
            expect(user).to be_valid
          end
        end
      RUBY
    end

    it 'does not register an offense for it blocks with expect blocks' do
      expect_no_offenses(<<~RUBY)
        describe 'User' do
          it { expect { user.save }.to change { User.count }.by(1) }
          it { expect { user.destroy }.to change { User.count }.by(-1) }
        end
      RUBY
    end

    it 'does not register an offense for single it block' do
      expect_no_offenses(<<~RUBY)
        describe 'User' do
          it { expect(user.name).to eq('John') }
        end
      RUBY
    end

    it 'does not register an offense for it blocks separated by context' do
      expect_no_offenses(<<~RUBY)
        describe 'User' do
          it { expect(user.name).to eq('John') }

          context 'when validating' do
            it { expect(user).to be_valid }
          end
        end
      RUBY
    end

    it 'detects consecutive multiline it blocks' do
      expect_offense(<<~RUBY)
        describe 'User' do
          it do
            expect(user.name).to eq('John')
            expect(user.email).to be_present
          end
          it do
          ^^ Avoid consecutive `it` blocks. Group related assertions in a single `it` or separate them with `context` or `describe`.
            expect(user).to be_valid
          end
        end
      RUBY
    end

    it 'does not register an offense for it blocks separated by comments' do
      expect_no_offenses(<<~RUBY)
        describe 'User' do
          it { expect(user.name).to eq('John') }
          # Some comment explaining the next test
          it { expect(user).to be_valid }
        end
      RUBY
    end

    it 'does not register an offense when it blocks contain expect with blocks' do
      expect_no_offenses(<<~RUBY)
        describe 'User' do
          it { expect { user.save! }.to change { User.count }.by(1) }
          it { expect { user.update!(name: 'Jane') }.to change { user.name } }
        end
      RUBY
    end
  end

  context 'with OnlyWithoutDescription: false' do
    let(:config) do
      RuboCop::Config.new('RSpec/ConsecutiveItBlocks' => { 'OnlyWithoutDescription' => false })
    end

    it 'registers an offense for consecutive it blocks with descriptions' do
      expect_offense(<<~RUBY)
        describe 'User' do
          it 'has a name' do
            expect(user.name).to eq('John')
          end
          it 'is valid' do
          ^^^^^^^^^^^^^ Avoid consecutive `it` blocks. Group related assertions in a single `it` or separate them with `context` or `describe`.
            expect(user).to be_valid
          end
        end
      RUBY
    end

    it 'detects multiple consecutive blocks with descriptions' do
      expect_offense(<<~RUBY)
        describe 'User' do
          it 'has a name' do
            expect(user.name).to eq('John')
          end
          it 'has an email' do
          ^^^^^^^^^^^^^^^^^ Avoid consecutive `it` blocks. Group related assertions in a single `it` or separate them with `context` or `describe`.
            expect(user.email).to be_present
          end
          it 'is valid' do
          ^^^^^^^^^^^^^ Avoid consecutive `it` blocks. Group related assertions in a single `it` or separate them with `context` or `describe`.
            expect(user).to be_valid
          end
        end
      RUBY
    end

    it 'does not register an offense for it blocks with expect blocks' do
      expect_no_offenses(<<~RUBY)
        describe 'User' do
          it 'creates a user' do
            expect { User.create(name: 'John') }.to change { User.count }.by(1)
          end
          it 'validates the user' do
            expect { user.save! }.not_to raise_error
          end
        end
      RUBY
    end

    it 'detects mixed descriptions and no descriptions' do
      expect_offense(<<~RUBY)
        describe 'User' do
          it 'has a name' do
            expect(user.name).to eq('John')
          end
          it do
          ^^ Avoid consecutive `it` blocks. Group related assertions in a single `it` or separate them with `context` or `describe`.
            expect(user).to be_valid
          end
        end
      RUBY
    end
  end
end
