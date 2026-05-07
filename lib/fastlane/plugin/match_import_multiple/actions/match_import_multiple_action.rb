require 'fastlane/action'
require 'fastlane_core/configuration/configuration'
require_relative '../helper/match_import_multiple_helper'

module Fastlane
  module Actions
    class MatchImportMultipleAction < Action
      def self.run(params)
        require 'match/importer'

        # Mirror what `fastlane match import` does after building its Configuration:
        # load Matchfile defaults so storage/type/etc are picked up automatically.
        begin
          params.load_configuration_file("Matchfile")
        rescue StandardError
          # Matchfile is optional
        end

        importer = ::Match::Importer.new

        # Same prompt order as upstream `fastlane match import`: cert -> p12 -> profile(s).
        cert_path = importer.ensure_valid_file_path(params[:cert_path], "Certificate", ".cer")
        p12_path  = importer.ensure_valid_file_path(params[:p12_path], "Private key", ".p12")

        profile_paths = resolve_profile_paths(params[:profile_paths])
        UI.user_error!("No provisioning profiles provided") if profile_paths.empty?

        profile_paths.each_with_index do |profile_path, idx|
          UI.message("Importing profile #{idx + 1}/#{profile_paths.length}: #{profile_path}")
          importer.import_cert(
            params,
            cert_path: cert_path,
            p12_path: p12_path,
            profile_path: profile_path
          )
        end

        UI.success("Imported #{profile_paths.length} provisioning profile(s) into the match repo")
      end

      # Mirrors upstream match's interactive UX:
      #   - Array given           -> use as-is
      #   - String (single/CSV)   -> split on commas
      #   - nil                   -> prompt the user (comma-separated input)
      # Each path is normalized to an absolute path and verified to exist.
      def self.resolve_profile_paths(value)
        raw = case value
              when Array
                value
              when String
                value.split(",")
              when nil
                UI.input("Provisioning profile (.mobileprovision or .provisionprofile) path(s), comma-separated, or leave empty to skip:").split(",")
              else
                UI.user_error!("Invalid profile_paths value: #{value.inspect}")
              end

        raw.map { |entry| entry.to_s.strip }.reject(&:empty?).map do |path|
          absolute = File.absolute_path(path)
          UI.user_error!("Provisioning profile does not exist at path: #{absolute}") unless File.exist?(absolute)
          absolute
        end
      end

      def self.description
        "Import multiple provisioning profiles into a match repo in a single invocation"
      end

      def self.details
        <<~DETAILS
          Wraps fastlane match's Importer so you can pass an array of provisioning
          profile paths together with a single shared certificate and private key.
          Iterates over the profiles and delegates to the unmodified upstream
          Match::Importer#import_cert. All match options (storage backend, type,
          team, App Store Connect API key, encryption settings, Matchfile, etc.)
          are forwarded as-is.
        DETAILS
      end

      def self.authors
        ["Bogdan Matran"]
      end

      def self.return_value
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end

      def self.available_options
        require 'match/options'

        plugin_options = [
          FastlaneCore::ConfigItem.new(
            key: :profile_paths,
            description: "Array (or comma-separated string) of provisioning profile paths to import. Prompts interactively if omitted, mirroring `fastlane match import`",
            skip_type_validation: true,
            optional: true
          ),
          FastlaneCore::ConfigItem.new(
            key: :cert_path,
            description: "Path to the .cer certificate (shared across all profiles). Prompts interactively if omitted",
            type: String,
            optional: true,
            verify_block: proc { |value| UI.user_error!("Certificate not found at path: #{value}") if value && !File.exist?(value) }
          ),
          FastlaneCore::ConfigItem.new(
            key: :p12_path,
            description: "Path to the .p12 private key (shared across all profiles). Prompts interactively if omitted",
            type: String,
            optional: true,
            verify_block: proc { |value| UI.user_error!("Private key not found at path: #{value}") if value && !File.exist?(value) }
          )
        ]

        reserved_keys = plugin_options.map(&:key)
        match_options = ::Match::Options.available_options.reject { |opt| reserved_keys.include?(opt.key) }

        plugin_options + match_options
      end

      def self.example_code
        [
          'match_import_multiple(
            type: "appstore",
            git_url: "git@github.com:your-org/certs.git",
            cert_path: "./assets/dist.cer",
            p12_path: "./assets/dist.p12",
            profile_paths: [
              "./assets/AppStore_app1.mobileprovision",
              "./assets/AppStore_app2.mobileprovision",
              "./assets/AppStore_app3.mobileprovision"
            ]
          )'
        ]
      end

      def self.category
        :code_signing
      end
    end
  end
end
