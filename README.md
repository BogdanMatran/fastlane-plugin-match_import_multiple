# match_import_multiple plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-match_import_multiple)

## About match_import_multiple

Wraps _match_'s `Importer` so a single invocation can register many provisioning profiles for the same certificate. _match_'s built-in `match import` only accepts one `.mobileprovision` (or `.provisionprofile`) per call, which means teams managing many bundle identifiers under the same signing certificate have to run the import once per profile — repeating the same App Store Connect login, the same git/S3 storage round trip, and the same Matchfile configuration each time.

This plugin keeps the same UX as upstream `fastlane match import` (cert → p12 → profile prompts, `Matchfile` auto-loaded, all _match_ options forwarded as-is) and only changes the profile argument, which now accepts an `Array` of paths or a comma-separated `String`. The action loops over the profiles and delegates each one to the unmodified upstream `Match::Importer#import_cert`, so behavior stays consistent with stock _fastlane_ and future _fastlane_ releases require no code changes here.

## Installation

Add the plugin to your project's `fastlane/Pluginfile`:

```ruby
gem 'fastlane-plugin-match_import_multiple',
    git: 'https://github.com/BogdanMatran/fastlane-plugin-match_import_multiple.git',
    branch: 'main'
```

Then make sure your project's `Gemfile` evaluates the `Pluginfile`:

```ruby
# Gemfile
source "https://rubygems.org"
gem 'fastlane'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
```

Install:

```bash
bundle install
```

## Usage

### From a `Fastfile`

```ruby
lane :import_profiles do
  match_import_multiple(
    type: "appstore",
    cert_path: "./assets/dist.cer",
    p12_path:  "./assets/dist.p12",
    profile_paths: [
      "./assets/AppStore_app.mobileprovision",
      "./assets/AppStore_app.ShareExtension.mobileprovision",
      "./assets/AppStore_app.NotificationExtension.mobileprovision"
    ]
  )
end
```

`git_url`, `username`, `team_id`, and other _match_ options are picked up from your project's `Matchfile` and `Appfile` automatically — exactly like with `fastlane match import`.

Run it:

```bash
bundle exec fastlane import_profiles
```

### From the CLI (no lane needed)

```bash
bundle exec fastlane run match_import_multiple \
  type:appstore \
  cert_path:./assets/dist.cer \
  p12_path:./assets/dist.p12 \
  profile_paths:./assets/profile1.mobileprovision,./assets/profile2.mobileprovision
```

`profile_paths` accepts a comma-separated string on the CLI; arrays are normalized internally.

### Interactive (mirrors upstream `fastlane match import`)

If you omit any of `cert_path`, `p12_path`, or `profile_paths`, the plugin prompts for them in the same order as `fastlane match import`:

```bash
bundle exec fastlane run match_import_multiple type:appstore
# Certificate (.cer) path: ./assets/dist.cer
# Private key (.p12) path: ./assets/dist.p12
# Provisioning profile (.mobileprovision or .provisionprofile) path(s),
#   comma-separated, or leave empty to skip: ./a.mobileprovision,./b.mobileprovision
```

## Parameters

| Parameter        | Type            | Description                                                                                          |
| ---------------- | --------------- | ---------------------------------------------------------------------------------------------------- |
| `profile_paths`  | `Array[String]` or comma-separated `String` | Provisioning profile paths to import. Prompts interactively if omitted. |
| `cert_path`      | `String`        | Path to the `.cer` certificate (shared across all profiles). Prompts interactively if omitted.       |
| `p12_path`       | `String`        | Path to the `.p12` private key (shared across all profiles). Prompts interactively if omitted.       |
| _all match opts_ | varies          | Every option that `fastlane match import` accepts (`type`, `git_url`, `storage_mode`, `api_key_path`, `username`, `team_id`, `skip_certificate_matching`, `force_legacy_encryption`, etc.) is forwarded as-is. |

## Behavior notes

- **One commit per profile.** Each profile triggers its own `Match::Importer#import_cert` call, which clones the certs repo, copies the profile, and pushes a commit. Importing _N_ profiles produces _N_ commits in the certs repo. This keeps the plugin a thin wrapper around upstream and resilient to future _match_ changes.
- **`app_identifier` is not required for import.** _match_'s option list declares `app_identifier` as required, but the import flow reads bundle ids from each `.mobileprovision` file directly. The plugin avoids forcing the prompt by passing the configuration straight through to `Match::Importer`, the same way upstream `match import` does.
- **`Matchfile` is auto-loaded** by the plugin, mirroring upstream's behavior. You don't need to repeat `git_url`, `type`, `storage_mode`, etc. in the action call if your `Matchfile` already sets them.

## Run tests for this plugin

```
bundle install
bundle exec rake
```

This runs RSpec specs and RuboCop. To auto-fix style issues:

```
bundle exec rubocop -a
```

## Troubleshooting

If you have trouble using _fastlane_ plugins, check the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
