require 'match/importer'

describe Fastlane::Actions::MatchImportMultipleAction do
  let(:cert_path) { File.expand_path("fixtures/test.cer", __dir__) }
  let(:p12_path) { File.expand_path("fixtures/test.p12", __dir__) }
  let(:profile_a) { File.expand_path("fixtures/profile_a.mobileprovision", __dir__) }
  let(:profile_b) { File.expand_path("fixtures/profile_b.mobileprovision", __dir__) }

  before do
    [cert_path, p12_path, profile_a, profile_b].each do |path|
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "stub") unless File.exist?(path)
    end
  end

  def build_config(extra = {})
    FastlaneCore::Configuration.create(
      Fastlane::Actions::MatchImportMultipleAction.available_options,
      {
        type: "appstore",
        git_url: "git@example.com:certs.git",
        app_identifier: "com.example.app",
        username: "test@example.com"
      }.merge(extra)
    )
  end

  def stub_importer(allow_cert: cert_path, allow_p12: p12_path)
    importer = instance_double(Match::Importer)
    allow(Match::Importer).to receive(:new).and_return(importer)
    allow(importer).to receive(:ensure_valid_file_path).with(anything, "Certificate", ".cer").and_return(allow_cert)
    allow(importer).to receive(:ensure_valid_file_path).with(anything, "Private key", ".p12").and_return(allow_p12)
    importer
  end

  describe '#run' do
    it 'invokes Match::Importer#import_cert once per profile when given an Array' do
      config = build_config(
        profile_paths: [profile_a, profile_b],
        cert_path: cert_path,
        p12_path: p12_path
      )

      importer = stub_importer

      expect(importer).to receive(:import_cert).with(
        kind_of(FastlaneCore::Configuration),
        cert_path: cert_path,
        p12_path: p12_path,
        profile_path: profile_a
      ).ordered
      expect(importer).to receive(:import_cert).with(
        kind_of(FastlaneCore::Configuration),
        cert_path: cert_path,
        p12_path: p12_path,
        profile_path: profile_b
      ).ordered

      Fastlane::Actions::MatchImportMultipleAction.run(config)
    end

    it 'splits a comma-separated profile_paths string' do
      config = build_config(
        profile_paths: "#{profile_a}, #{profile_b}",
        cert_path: cert_path,
        p12_path: p12_path
      )

      importer = stub_importer
      expect(importer).to receive(:import_cert).twice

      Fastlane::Actions::MatchImportMultipleAction.run(config)
    end

    it 'prompts for profile paths when profile_paths is nil' do
      config = build_config(
        cert_path: cert_path,
        p12_path: p12_path
      )

      expect(Fastlane::UI).to receive(:input).and_return("#{profile_a},#{profile_b}")

      importer = stub_importer
      expect(importer).to receive(:import_cert).twice

      Fastlane::Actions::MatchImportMultipleAction.run(config)
    end

    it 'asks for cert and p12 before profiles (upstream prompt order)' do
      config = build_config(profile_paths: [profile_a])

      importer = instance_double(Match::Importer)
      allow(Match::Importer).to receive(:new).and_return(importer)

      expect(importer).to receive(:ensure_valid_file_path).with(nil, "Certificate", ".cer").ordered.and_return(cert_path)
      expect(importer).to receive(:ensure_valid_file_path).with(nil, "Private key", ".p12").ordered.and_return(p12_path)
      expect(importer).to receive(:import_cert).with(
        kind_of(FastlaneCore::Configuration),
        cert_path: cert_path,
        p12_path: p12_path,
        profile_path: profile_a
      ).ordered

      Fastlane::Actions::MatchImportMultipleAction.run(config)
    end

    it 'errors when the user provides no profile paths interactively' do
      config = build_config(
        cert_path: cert_path,
        p12_path: p12_path
      )

      stub_importer
      allow(Fastlane::UI).to receive(:input).and_return("")

      expect do
        Fastlane::Actions::MatchImportMultipleAction.run(config)
      end.to raise_error(FastlaneCore::Interface::FastlaneError, /No provisioning profiles provided/)
    end
  end
end
