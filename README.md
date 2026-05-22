# jwulff/homebrew-tap

Homebrew formulae for [@jwulff](https://github.com/jwulff)'s tools.

## Usage

```bash
brew tap jwulff/tap
brew install jwulff/tap/<formula>
```

Or in one step:

```bash
brew install jwulff/tap/<formula>
```

## Formulae

| Formula | Description | Upstream |
|---|---|---|
| [dictamac](Formula/dictamac.rb) | macOS CLI for on-device audio transcription via SpeechAnalyzer | [jwulff/dictamac](https://github.com/jwulff/dictamac) |
| [steno](Formula/steno.rb) | macOS always-on speech-to-text TUI + MCP server (Swift daemon + Go CLI) | [jwulff/steno](https://github.com/jwulff/steno) |

## Requirements

Formulae here generally target macOS 26 (Tahoe) or later and may
require Xcode 26 / the matching Command Line Tools to build from
source. See each formula's `depends_on` block.

## Adding a formula

After tagging a release in the upstream repo:

1. Compute the source tarball SHA256:
   ```bash
   curl -sL https://github.com/jwulff/<repo>/archive/refs/tags/<tag>.tar.gz \
     | shasum -a 256
   ```
2. Update `Formula/<name>.rb` with the new `url`, `sha256`, and any
   dependency or version-floor changes.
3. Commit + push to this repo's `main`.
4. Verify with `brew install jwulff/tap/<name>` on a clean machine.

## License

Formulae are MIT-licensed, matching the upstream tools they package.
