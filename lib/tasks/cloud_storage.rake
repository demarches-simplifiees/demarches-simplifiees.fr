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
        content = (c == Procedure)? entry.logo : entry.content
        unless content.current_path.nil? || File.exist?(File.dirname(content.current_path) + '/uploaded')
          secure_token = SecureRandom.uuid
          filename = "#{entry.class.to_s.underscore}-#{secure_token}.pdf"
          puts "Uploading #{content.current_path}"
          begin
            @cont.create_object(filename, { content_type: "application/pdf"}, File.open(content.current_path))
            File.open(File.dirname(content.current_path) + '/uploaded', "w+"){ |f| f.write(File.basename(content.current_path)) }
            entry.update_column(c == Procedure ? :logo : :content, filename)
          rescue Errno::ENOENT
            puts "ERROR: #{content.current_path} does not exist!"
            File.open('upload_errors.report', "a+"){ |f| f.write(content.current_path) }
            error_count += 1
          end
        else
          puts "Skipping #{content.current_path}"
        end
      }
    }

    puts "There were #{error_count} errors while uploading files. See upload_errors.report file for details."
    puts 'Enf of migration'
  end

  desc 'Clear documents in tenant and revert file entries in database'
  task :revert do
    Rake::Task['cloudstorage:init'].invoke

    @cont.objects.each { |object|
      puts "Removing #{object}"
      @cont.delete_object(object)
    }

    [Cerfa, PieceJustificative, Procedure].each { |c|
      c.all.each { |entry|
        content = entry.content
        content = entry.logo if c == Procedure
        unless content.current_path.nil?
          if File.exist?(File.dirname(content.current_path) + '/uploaded')
            previous_filename = File.read(File.dirname(content.current_path) + '/uploaded')
            entry.update_column(c == Procedure ? :logo : :content, filename)
            puts "restoring #{content.current_path} db data to #{previous_filename}"
            FileUtils.rm(File.dirname(content.current_path) + '/uploaded')
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
      last_modified = DateTime.parse(details[:last_modified])
      @cont.delete_object(object) unless last_modified.utc >  (Time.now - 2.year).utc
    }
  end

end