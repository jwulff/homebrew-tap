# Homebrew formula for the cotrugli host collectors.
#
# Installs the Rust host-collector binaries from the cotrugli monorepo
# (github.com/jwulff/cotrugli): cotrugli-photos, cotrugli-imessage,
# cotrugli-contacts, and cotrugli-fs. One formula ships every collector binary
# so a new Mac gets the whole collector suite from a single `brew install`.
#
#   brew install --HEAD jwulff/homebrew-tap/cotrugli
#
# HEAD-ONLY, ON PURPOSE. jwulff/cotrugli is a PRIVATE repo. A pinned-version
# `url` tarball can't be fetched without HOMEBREW_GITHUB_API_TOKEN + a private
# release download strategy + tagged GitHub releases. The `--HEAD` git clone
# instead reuses the git credential helper John already has configured
# (`credential.https://github.com.helper = !gh auth git-credential`, with `gh`
# authed at `repo` scope), so it needs ZERO extra setup — a plain
# `brew install --HEAD` just works. The tradeoff is no version pin (always
# builds latest `main`) and the mandatory `--HEAD` flag. A signed/notarized
# stable release channel is deferred to the code-signing follow-up (issue #284).
class Cotrugli < Formula
  desc "macOS host collectors (Photos, iMessage, Contacts, Filesystem) for the cotrugli lake"
  homepage "https://github.com/jwulff/cotrugli"
  license "MIT"
  head "https://github.com/jwulff/cotrugli.git", branch: "main"

  # Rust is a build-only dependency: the binaries are self-contained once
  # compiled, so downstream users never need a Rust toolchain at runtime.
  depends_on "rust" => :build

  # The collectors are macOS-only: they read per-user macOS source DBs
  # (~/Library/Messages/chat.db, the Contacts store) and store their bearer
  # token in the macOS Keychain (security-framework). They will not build or
  # run on Linux.
  depends_on :macos

  def install
    # Each collector is its own crate in the workspace. `cargo install --path
    # <crate>` builds that crate's binary in release mode and drops it in
    # `#{prefix}/bin`. We install per-crate (rather than a workspace-root
    # `--path .`, which is ambiguous for a virtual workspace). `std_cargo_args`
    # supplies `--locked --root #{prefix}`; `--locked` builds against the
    # committed Cargo.lock so the install matches CI (the workspace pins serde /
    # serde_json / rusqlite to exact versions for canonical-byte stability).
    system "cargo", "install", *std_cargo_args(path: "packages/photos-collector")
    system "cargo", "install", *std_cargo_args(path: "packages/imessage-collector")
    system "cargo", "install", *std_cargo_args(path: "packages/contacts-collector")
    system "cargo", "install", *std_cargo_args(path: "packages/fs-collector")
  end

  def caveats
    <<~EOS
      The cotrugli collectors need a bearer token, and the Photos and iMessage
      collectors need macOS Full Disk Access, before they can run. One-time
      setup per collector:

        1. Mint a claim code in the cotrugli web app
           (Settings -> API Tokens), then enroll:

             cotrugli-photos   enroll --server https://cotrugli.com --code cotrc_...
             cotrugli-imessage enroll --server https://cotrugli.com --code cotrc_...
             cotrugli-contacts enroll --server https://cotrugli.com --code cotrc_...
             cotrugli-fs       enroll --server https://cotrugli.com --code cotrc_...

        2. Grant Full Disk Access to
             #{bin}/cotrugli-photos
             #{bin}/cotrugli-imessage
             #{bin}/cotrugli-fs
           in System Settings -> Privacy & Security -> Full Disk Access, so they
           can read the Photos library, ~/Library/Messages/chat.db, and the
           filesystem scan roots (Downloads/Desktop/Documents/screenshots).

        3. Schedule the LaunchAgent(s):

             cotrugli-photos   install-launchd --server https://cotrugli.com
             cotrugli-imessage install-launchd --server https://cotrugli.com
             cotrugli-contacts install-launchd --server https://cotrugli.com
             cotrugli-fs       install-launchd --server https://cotrugli.com

           Tip: dry-run first (local, no uploads) to see what would be captured:
             cotrugli-photos sweep --dry-run --server https://cotrugli.com
             cotrugli-fs     sweep --dry-run --server https://cotrugli.com

           The filesystem collector captures forward-only by default; run
             cotrugli-fs backfill --server https://cotrugli.com
           to opt into capturing the pre-existing tree.

      Check state any time with `cotrugli-imessage status --server https://cotrugli.com`.

      This is a source build — the binaries are compiled locally and are NOT
      code-signed or notarized, so they are not Gatekeeper-quarantined the way a
      downloaded binary would be. Signing/notarization is tracked in issue #284.
    EOS
  end

  test do
    # `--help` exits 0 on each binary (clap), proving it linked and parses its
    # CLI. We deliberately do not run `enroll`/`sweep`: those require a network
    # server, a Keychain token, and (for Photos/iMessage) Full Disk Access,
    # none of which exist in the `brew test` sandbox.
    assert_match "cotrugli", shell_output("#{bin}/cotrugli-photos --help")
    assert_match "cotrugli", shell_output("#{bin}/cotrugli-imessage --help")
    assert_match "cotrugli", shell_output("#{bin}/cotrugli-contacts --help")
    assert_match "cotrugli", shell_output("#{bin}/cotrugli-fs --help")
  end
end
