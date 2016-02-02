Swagger::Docs::Config.register_apis(
    {
        "1.0" => {
            # the extension used for the API
            :api_extension_type => :json,
            # the output location where your .json files are written to
            :api_file_path => "app/views/docs/",
            # the URL base path to your API
            :base_path => "https://tps.apientreprise.fr",
            # if you want to delete all .json files at each generation
            :clean_directory => false,
            # add custom attributes to api-docs
            :attributes => {
                :info => {
                    "title" => "TPS application",
                    "description" => "Doc des APIs de TPS",
                    "contact" => "contact@tps.apientreprise.fr",
                    "license" => "Apache 2.0",
                    "licenseUrl" => "http://www.apache.org/licenses/LICENSE-2.0.html"
                }
            }
        }
    })