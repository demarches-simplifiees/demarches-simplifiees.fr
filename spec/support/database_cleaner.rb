RSpec.configure do |config|
  expect_list = []

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation, except: expect_list)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, js: true) do
    DatabaseCleaner.strategy = :truncation, { except: expect_list }
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
