RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation, {:except => %w[evenement_vies formulaires types_piece_jointe]})
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
