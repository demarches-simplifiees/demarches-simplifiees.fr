namespace :cloudstorage do
  task init: :environment do
    os_config = (YAML.load_file(Fog.credentials_path))['default']
    @os = OpenStack::Connection.create(
      {
        username: os_config['openstack_username'],
        api_key: os_config['openstack_api_key'],
        auth_method: "password",
        auth_url: "https://auth.cloud.ovh.net/v2.0/",
        authtenant_name: os_config['openstack_tenant'],
        service_type: "object-store",
        region: os_config['openstack_region']
      }
    )
    @cont = @os.container(CarrierWave::Uploader::Base.fog_directory)
  end

  desc 'Move local attestations on cloud storage'
  task migrate: :environment do
    puts 'Starting migration'

    Rake::Task['cloudstorage:init'].invoke

    error_count = 0
    [Cerfa, PieceJustificative, Procedure].each { |c|
      c.all.each { |entry|
        content = (c == Procedure) ? entry.logo : entry.content
        if !(content.current_path.nil? || File.exist?(File.dirname(content.current_path) + '/uploaded'))
          secure_token = SecureRandom.uuid
          filename = "#{entry.class.to_s.underscore}-#{secure_token}#{File.extname(content.current_path)}"
          puts "Uploading #{content.current_path}"
          begin
            @cont.create_object(filename, {}, File.open(content.current_path))

            File.open(File.dirname(content.current_path) + '/uploaded', "w+") { |f| f.write(File.basename(content.current_path)) }
            File.open(File.dirname(content.current_path) + '/filename_cloudstorage', "w+") { |f| f.write(filename) }
            File.open(File.dirname(content.current_path) + '/secure_token_cloudstorage', "w+") { |f| f.write(secure_token) }

            entry.update_column(c == Procedure ? :logo : :content, filename)
            entry.update_column(c == Procedure ? :logo_secure_token : :content_secure_token, secure_token)
          rescue Errno::ENOENT
            puts "ERROR: #{content.current_path} does not exist!"
            File.open('upload_errors.report', "a+") { |f| f.write(content.current_path) }
            error_count += 1
          end
        else
          if content.current_path.present? && File.exist?(File.dirname(content.current_path) + '/uploaded')
            filename = File.open(File.dirname(content.current_path) + '/filename_cloudstorage', "r").read
            secure_token = File.open(File.dirname(content.current_path) + '/secure_token_cloudstorage', "r").read

            entry.update_column(c == Procedure ? :logo : :content, filename)
            entry.update_column(c == Procedure ? :logo_secure_token : :content_secure_token, secure_token)

            puts "RESTORE IN DATABASE: #{filename} "
          elsif content.current_path.present?
            puts "Skipping #{content.current_path}"
          end
        end
      }
    }

    puts "There were #{error_count} errors while uploading files. See upload_errors.report file for details."
    puts 'Enf of migration'
  end

  desc 'Clear documents in tenant and revert file entries in database'
  task :revert do
    Rake::Task['cloudstorage:init'].invoke

    [Cerfa, PieceJustificative, Procedure].each { |c|
      c.all.each { |entry|
        content = (c == Procedure) ? entry.logo : entry.content
        if content.current_path.present?
          if File.exist?(File.dirname(content.current_path) + '/uploaded')
            previous_filename = File.read(File.dirname(content.current_path) + '/uploaded')

            entry.update_column(c == Procedure ? :logo : :content, previous_filename)
            entry.update_column(c == Procedure ? :logo_secure_token : :content_secure_token, nil)

            puts "restoring #{content.current_path} db data to #{previous_filename}"

            @cont.delete_object(File.open(File.dirname(content.current_path) + '/filename_cloudstorage', "r").read)

            FileUtils.rm(File.dirname(content.current_path) + '/uploaded')
            FileUtils.rm(File.dirname(content.current_path) + '/filename_cloudstorage')
            FileUtils.rm(File.dirname(content.current_path) + '/secure_token_cloudstorage')
          end
        end
      }
    }
  end

  desc 'Clear old documents in tenant'
  task :clear do
    Rake::Task['cloudstorage:init'].invoke

    @cont.objects.each { |object|
      puts "Removing #{object}"
      @cont.delete_object(object)
    }
  end

  task :clear_old_objects do
    Rake::Task['cloudstorage:init'].invoke

    @cont.objects_detail.each { |object, details|
      last_modified = Time.zone.parse(details[:last_modified])
      @cont.delete_object(object) if last_modified.utc <= (Time.zone.now - 2.years).utc
    }
  end
end
