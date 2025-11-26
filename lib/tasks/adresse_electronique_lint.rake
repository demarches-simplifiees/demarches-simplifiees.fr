# frozen_string_literal: true

namespace :lint do
  desc 'Check for incorrect email address terminology in view and translation files'
  task :adresse_electronique do
    require 'fileutils'

    patterns = [
      /adresse(s)?\s+(email|mail|e-mail)/i,
      /votre\s+(email|mail|e-mail)/i,
    ]

    extensions = %w[.haml .erb .html .yml .yaml]
    directories = [
      'app/views',
      'app/components',
      'config/locales',
    ]

    offenses = []

    directories.each do |dir|
      next unless Dir.exist?(dir)

      Dir.glob("#{dir}/**/*").each do |file|
        next unless File.file?(file)
        next unless extensions.include?(File.extname(file))

        content = File.read(file)
        patterns.each do |pattern|
          content.scan(pattern) do |_match|
            match_data = Regexp.last_match
            line_number = content[0...match_data.begin(0)].count("\n") + 1
            offenses << {
              file: file,
              line: line_number,
              match: match_data[0],
            }
          end
        end
      end
    end

    if offenses.any?
      puts "\n❌ Found #{offenses.size} offense(s) using incorrect email terminology:"
      puts "\nUse 'adresse électronique' instead of 'adresse email', 'adresse mail', or 'adresse e-mail'\n\n"
      offenses.each do |offense|
        puts "  #{offense[:file]}:#{offense[:line]}"
        puts "    Found: #{offense[:match]}"
      end
      puts
      exit 1
    else
      puts "✅ No offenses found for email address terminology"
    end
  end
end
