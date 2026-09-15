# How to release

Releases are built and published by GitHub Actions
(`.github/workflows/release.yml`). Push an annotated semver tag and the
workflow does the rest:

```bash
git tag -a 0.8.0 -m "Fugitive 3D 0.8.0" -m "What changed, one item per line."
git push origin 0.8.0
```

The tag body becomes the release notes, the Google Play "What's new" text and
the Discord announcement, so write it for players. The workflow:

1. Exports every preset in `export_presets.cfg` headlessly with the Godot
   version in `.godot-version`, stamping `X.Y.Z` into the presets and an
   Android version code of `major*10000 + minor*100 + patch` (`0.8.0` is
   `800`). `GAME_VERSION` in `common/UserData.gd` is the network protocol
   number and is bumped by hand, separately.
2. Creates the GitHub release with every build attached: zipped desktop
   builds (binary, `.pck`, GDExtension libraries, and the MSVC runtime on
   Windows), the two APKs and the Play AAB.
3. Pushes the itch.io channels with butler, uploads the AAB to the Google
   Play production track with fastlane, and uploads the Quest APK to the
   Meta Horizon Store production channel.
4. Publishes the dedicated server as a Docker image (see
   [Docker](../README.md#docker)) and tells the official game servers to
   install the new Linux server build.
5. Posts to the Discord release channel. If that step is the only failure,
   the `Announce Release` workflow re-sends it for a given tag.

## Running one leg on its own

Four legs can also be run on their own from the Actions tab, to retry one
that failed without repeating a whole release. Each takes a tag and works on
any tag that already has a release:

- `Publish to Google Play` uploads that release's AAB. It defaults to the
  internal track with "validate only" checked, which exercises the service
  account without publishing, so it doubles as the credential check. Uncheck
  it to promote a build to another track.
- `Publish to Meta Horizon Store` uploads that release's Quest APK. It
  defaults to the ALPHA channel, which reaches only testers you have added,
  so a manual run cannot publish to the store by accident.
- `Update Game Servers` installs a tag on the official servers, which is also
  how you roll them back and how to check the webhook without releasing.
- `Announce Release` posts the Discord message.

The Quest preset pins its target SDK to 34 because Meta rejects anything
higher, while Google Play requires 35 or above. The two stores disagree, so
that setting belongs to the Quest preset alone and must not be applied to the
Play preset.

## Secrets

Set these under the repository's Actions secrets:

| Secret | Purpose |
| --- | --- |
| `GAME_KEYS_JSON` | Contents of `keys.json` (see `keys.json.example`); packed into the client |
| `ANDROID_KEYSTORE_BASE64` | The upload keystore, base64 encoded |
| `ANDROID_KEYSTORE_ALIAS` | Key alias in that keystore |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password (key password must match; Godot signs with one) |
| `BUTLER_API_KEY` | itch.io API key |
| `GOOGLE_PLAY_JSON` | Play Console service account JSON with release rights on the app |
| `META_APP_ID` | Meta app id, from the app's Horizon developer dashboard |
| `META_APP_SECRET` | That app's secret, under API in the same dashboard |
| `SERVER_DEPLOY_WEBHOOK_URL` | Base URL of the game servers' webhook receiver |
| `SERVER_DEPLOY_WEBHOOK_SECRET` | Shared secret that signs the server update request |
| `DISCORD_WEBHOOK` | Discord channel webhook URL |

## Dry runs

Run the `Release` workflow by hand from any branch with `dry_run` checked
(the default). It builds and packages everything and uploads the result as
the `release-artifacts` workflow artifact without publishing anywhere.

The same scripts run locally, which is the fastest way to debug an export:

```bash
VERSION=0.0.1 VERSION_CODE=1 bash .github/scripts/set-version.sh
GODOT_BIN=/path/to/godot bash .github/scripts/export-all.sh
VERSION=0.0.1 VERSION_CODE=1 bash .github/scripts/package-artifacts.sh
```

Android exports need `JAVA_HOME` and `ANDROID_HOME` set before the first
Godot run, a `keys.json` in the project root, and the release keystore in
`GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER` and `_PASSWORD`. Restore
`export_presets.cfg` afterwards; `set-version.sh` edits it in place.
