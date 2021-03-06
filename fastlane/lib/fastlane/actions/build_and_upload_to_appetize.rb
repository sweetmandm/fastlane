module Fastlane
  module Actions
    class BuildAndUploadToAppetizeAction < Action
      def self.run(params)
        tmp_path = "/tmp/fastlane_build"

        xcodebuild_configs = params[:xcodebuild]
        xcodebuild_configs[:sdk] = "iphonesimulator"
        xcodebuild_configs[:derivedDataPath] = tmp_path
        xcodebuild_configs[:scheme] ||= params[:scheme] if params[:scheme].to_s.length > 0

        Actions::XcodebuildAction.run(xcodebuild_configs)

        app_path = Dir[File.join(tmp_path, "**", "*.app")].last
        UI.user_error!("Couldn't find app") unless app_path

        zipped_ipa = Actions::ZipAction.run(path: app_path,
                                     output_path: File.join(tmp_path, "Result.zip"))

        Actions::AppetizeAction.run(path: zipped_ipa,
                               api_token: params[:api_token])

        public_key = Actions.lane_context[SharedValues::APPETIZE_PUBLIC_KEY]
        UI.success("Generated Public Key: #{Actions.lane_context[SharedValues::APPETIZE_PUBLIC_KEY]}")

        FileUtils.rm_rf(tmp_path)

        return public_key
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Generate and upload an ipa file to appetize.io"
      end

      def self.details
        "This should be called from danger"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :xcodebuild,
                                       description: "Parameters that are passed to the xcodebuild action",
                                       type: Hash,
                                       default_value: {},
                                       short_option: '-x',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :scheme,
                                       description: "The scheme to build. Can also be passed using the `xcodebuild` parameter",
                                       type: String,
                                       short_option: '-s',
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "APPETIZE_API_TOKEN",
                                       description: "Appetize.io API Token",
                                       is_string: true)
        ]
      end

      def self.output
      end

      def self.return_value
        ""
      end

      def self.authors
        ["KrauseFx"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
