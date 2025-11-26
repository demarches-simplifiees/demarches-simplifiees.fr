# frozen_string_literal: true

require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../lib/cops/french_apostrophe'

RSpec.describe RuboCop::Cop::DS::FrenchApostrophe do
  subject(:cop) { described_class.new }

  it 'detects simple apostrophe in French text' do
    expect_offense(<<~RUBY)
      "l'adresse électronique"
      ^^^^^^^^^^^^^^^^^^^^^^^^ DS/FrenchApostrophe: Use modifier letter apostrophe ʼ (U+02BC) instead of ' (U+0027) or ' (U+2019) in French text
    RUBY

    expect_correction(<<~RUBY)
      "lʼadresse électronique"
    RUBY
  end

  it 'detects curved apostrophe in French text' do
    expect_offense(<<~RUBY)
      "l'utilisateur"
      ^^^^^^^^^^^^^^^ DS/FrenchApostrophe: Use modifier letter apostrophe ʼ (U+02BC) instead of ' (U+0027) or ' (U+2019) in French text
    RUBY

    expect_correction(<<~RUBY)
      "lʼutilisateur"
    RUBY
  end

  it 'ignores already correct apostrophes' do
    expect_no_offenses(<<~RUBY)
      "lʼadresse électronique"
    RUBY
  end

  it 'ignores code-like strings' do
    expect_no_offenses(<<~RUBY)
      "user.method_name"
    RUBY
  end

  it 'handles multiple French contractions' do
    expect_offense(<<~RUBY)
      "qu'il n'y a plus d'utilisateurs"
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ DS/FrenchApostrophe: Use modifier letter apostrophe ʼ (U+02BC) instead of ' (U+0027) or ' (U+2019) in French text
    RUBY

    expect_correction(<<~RUBY)
      "quʼil nʼy a plus dʼutilisateurs"
    RUBY
  end
end
