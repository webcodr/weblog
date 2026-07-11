# Post Metadata Backfill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every blog post a curated description and one to three controlled topics without changing existing metadata.

**Architecture:** Update YAML front matter in four editorial batches grouped by publication era. Extend the existing shell regression suite batch-by-batch so each metadata group is proven incomplete before editing and complete afterward; finish with a collection-wide audit and Hugo build.

**Tech Stack:** Hugo, Markdown with YAML front matter, Bash regression checks

---

## File Structure

- Modify: `tests/blog-discovery.sh` to add reusable metadata assertions and collection-wide checks.
- Modify: `content/post/*.md` to add only missing `topics` and `description` fields.
- Preserve: Existing topics in posts from 2024 onward and existing descriptions in the two July 2026 posts.

Do not modify or discard unrelated worktree changes. In particular, preserve the current uncommitted link, navigation, and mobile-spacing changes in `assets/css/webcodr.css`, `tests/blog-discovery.sh`, and `themes/webcodr/layouts/partials/post-navigation.html`.

Use flow-style topics consistently:

```yaml
topics: [developer-tools, programming]
description: A concise sentence ending with punctuation.
```

## Controlled Vocabulary

Reuse the existing `developer-tools`, `kotlin`, `linux`, `omarchy`, `programming`, and `rust` topics. Introduce only these additional slugs:

```text
edgerouter
hardware
javascript
lets-encrypt
macos
networking
performance
php
site-news
software-development
software-industry
testing
vdsl
web-development
```

### Task 1: Add Metadata Assertions and Backfill Imported Posts

**Files:**
- Modify: `tests/blog-discovery.sh`
- Modify: `content/post/2015-12-05_amplify-2-0.md`
- Modify: `content/post/2015-12-05_array-almighty.md`
- Modify: `content/post/2015-12-05_codrpress.md`
- Modify: `content/post/2015-12-05_ihk-agile.md`
- Modify: `content/post/2015-12-05_menlo-park-start-your-photocopiers.md`
- Modify: `content/post/2015-12-05_php-autoloader-nach-dem-psr-0-standard.md`
- Modify: `content/post/2015-12-05_php-tip-limonade.md`
- Modify: `content/post/2015-12-05_pythonpress.md`
- Modify: `content/post/2015-12-05_responsive-bilder-mit-wordpress.md`
- Modify: `content/post/2015-12-05_retina-display-taugliche-css-hintergrundbilder.md`
- Modify: `content/post/2015-12-05_say-hello-to-mango.md`
- Modify: `content/post/2015-12-05_schnellere-websites-mit-requirejs.md`
- Modify: `content/post/2015-12-05_services-ftw.md`
- Modify: `content/post/2015-12-05_sublime-text-2.md`
- Modify: `content/post/2015-12-05_tastaturen.md`
- Modify: `content/post/2015-12-05_upload-probleme-mit-php-via-fastcgi.md`

- [ ] **Step 1: Add a reusable front matter assertion**

Add this function after `assert_count()` in `tests/blog-discovery.sh`:

```bash
assert_post_metadata() {
	local post="$root/content/post/$1"
	grep -Eq '^topics: \[[a-z0-9-]+(, [a-z0-9-]+){0,2}\]$' "$post" || fail "expected 1-3 normalized topics in $post"
	grep -Eq '^description: .+[.!?]$' "$post" || fail "expected a punctuated description in $post"
}
```

Add these calls immediately before the final success message:

```bash
assert_post_metadata "2015-12-05_amplify-2-0.md"
assert_post_metadata "2015-12-05_array-almighty.md"
assert_post_metadata "2015-12-05_codrpress.md"
assert_post_metadata "2015-12-05_ihk-agile.md"
assert_post_metadata "2015-12-05_menlo-park-start-your-photocopiers.md"
assert_post_metadata "2015-12-05_php-autoloader-nach-dem-psr-0-standard.md"
assert_post_metadata "2015-12-05_php-tip-limonade.md"
assert_post_metadata "2015-12-05_pythonpress.md"
assert_post_metadata "2015-12-05_responsive-bilder-mit-wordpress.md"
assert_post_metadata "2015-12-05_retina-display-taugliche-css-hintergrundbilder.md"
assert_post_metadata "2015-12-05_say-hello-to-mango.md"
assert_post_metadata "2015-12-05_schnellere-websites-mit-requirejs.md"
assert_post_metadata "2015-12-05_services-ftw.md"
assert_post_metadata "2015-12-05_sublime-text-2.md"
assert_post_metadata "2015-12-05_tastaturen.md"
assert_post_metadata "2015-12-05_upload-probleme-mit-php-via-fastcgi.md"
```

- [ ] **Step 2: Run the regression check and verify RED**

Run: `bash tests/blog-discovery.sh`

Expected: FAIL on `2015-12-05_amplify-2-0.md` because it has no normalized topics.

- [ ] **Step 3: Add the exact curated metadata**

Insert these exact values before each file's closing front matter delimiter:

| File | Topics | Description |
|---|---|---|
| `2015-12-05_amplify-2-0.md` | `[web-development, software-development]` | `Amplify 2.0 erhält kramdown, HTML-Bereinigung, schnelleres Syntax-Highlighting, ein AngularJS-Frontend und eine JSON-API.` |
| `2015-12-05_array-almighty.md` | `[php, programming]` | `Ein Vergleich mit Scala führt zu PHP-Collection-Klassen, die Array-Zugriffe, Listenoperationen und verkettete Methoden vereinen.` |
| `2015-12-05_codrpress.md` | `[php, web-development]` | `CodrPress entsteht als PHP-Blogsystem mit Silex, MongoDB, Markdown und Syntax-Highlighting.` |
| `2015-12-05_ihk-agile.md` | `[software-development]` | `Der Beitrag kritisiert starres Projektmanagement in der IT-Ausbildung und plädiert für praxisnahe agile Entwicklungsmethoden.` |
| `2015-12-05_menlo-park-start-your-photocopiers.md` | `[software-industry]` | `Ähnliche JavaScript-Schnipsel von Twitter und Facebook dienen als Plädoyer gegen Trivialpatente und schädliche Patentkriege.` |
| `2015-12-05_php-autoloader-nach-dem-psr-0-standard.md` | `[php, programming]` | `Der Beitrag erklärt PSR-0 und implementiert einen interoperablen PHP-Autoloader für Namespaces und Klassen.` |
| `2015-12-05_php-tip-limonade.md` | `[php, web-development]` | `Limonade wird als schlankes PHP-Microframework für Routing, Templates, Hooks und JSON vorgestellt.` |
| `2015-12-05_pythonpress.md` | `[programming, web-development]` | `Ein Lernprojekt zeigt, wie mit Flask, Jinja2 und MongoEngine eine Python-Version von CodrPress auf MongoDB entsteht.` |
| `2015-12-05_responsive-bilder-mit-wordpress.md` | `[php, web-development]` | `Ein WordPress-Filter entfernt feste Bildabmessungen, damit eingebettete Bilder in responsiven Layouts per CSS mitskalieren.` |
| `2015-12-05_retina-display-taugliche-css-hintergrundbilder.md` | `[web-development]` | `CSS-Media-Queries liefern hochauflösende Hintergrundbilder für Retina-Displays in der gewünschten Darstellungsgröße aus.` |
| `2015-12-05_say-hello-to-mango.md` | `[php, programming]` | `Mango wird als leichtgewichtiger PHP-ODM für MongoDB mit Models, Abfragen, Hydration und Composer-Installation vorgestellt.` |
| `2015-12-05_schnellere-websites-mit-requirejs.md` | `[javascript, web-development]` | `RequireJS strukturiert JavaScript in Module, löst Abhängigkeiten auf und lädt Skripte asynchron.` |
| `2015-12-05_services-ftw.md` | `[programming, web-development]` | `HTTP-Dienste verbinden PHP, Python und Ruby für anwendungsunabhängiges Markdown-Rendering und Syntax-Highlighting.` |
| `2015-12-05_sublime-text-2.md` | `[developer-tools]` | `Sublime Text 2 wird als schneller, plattformübergreifender und umfassend konfigurierbarer Editor empfohlen.` |
| `2015-12-05_tastaturen.md` | `[developer-tools, hardware]` | `Ein Vergleich erklärt Technik, Schaltertypen und Vorzüge mechanischer Tastaturen für Vieltipper, Entwickler und Spieler.` |
| `2015-12-05_upload-probleme-mit-php-via-fastcgi.md` | `[php, web-development]` | `Ein zu niedriges MaxRequestLen-Limit von Apache mod_fcgid verursacht Uploadfehler und wird über FastCGI erhöht.` |

For every row, add:

```yaml
topics: TOPICS_FROM_TABLE
description: DESCRIPTION_FROM_TABLE
```

- [ ] **Step 4: Run the regression check and verify GREEN**

Run: `bash tests/blog-discovery.sh`

Expected: `Blog discovery checks passed.`

- [ ] **Step 5: Commit the imported-post batch**

```bash
git add tests/blog-discovery.sh content/post/2015-12-05_*.md
git commit -m "content: classify imported posts"
```

### Task 2: Backfill Networking and Infrastructure Posts

**Files:**
- Modify: `tests/blog-discovery.sh`
- Modify: the 13 post files listed in the table below

- [ ] **Step 1: Add failing metadata assertions for this batch**

Add one `assert_post_metadata "FILENAME"` call for every filename in the Task 2 metadata table immediately after the Task 1 calls.

- [ ] **Step 2: Run the regression check and verify RED**

Run: `bash tests/blog-discovery.sh`

Expected: FAIL on `2017-01-07_vdsl-vigor-130-edgerouter.md` because its metadata is missing.

- [ ] **Step 3: Add the exact curated metadata**

| File | Topics | Description |
|---|---|---|
| `2017-01-07_vdsl-vigor-130-edgerouter.md` | `[edgerouter, networking, vdsl]` | `Anleitung zur Einrichtung eines Telekom-VDSL-Anschlusses mit Vigor 130, EdgeRouter X, PPPoE und IPv6.` |
| `2017-01-07_vodafone-zu-telekom.md` | `[networking, vdsl]` | `Ein Erfahrungsbericht über den Wechsel von Vodafone-Kabel zu Telekom VDSL wegen Überlastung, Packet Loss und schlechtem Peering.` |
| `2017-01-09_webpack-2-setup.md` | `[javascript, web-development]` | `A practical Webpack 2 setup for compiling Pug templates, SCSS stylesheets, and ES2015 JavaScript with Babel.` |
| `2017-01-15_edgerouter-x-vs-mikrotik-hex.md` | `[edgerouter, hardware, networking]` | `EdgeRouter X und MikroTik hEX im Vergleich mit Ausstattung, Bedienung und Routing-Leistung mit und ohne Hardware-NAT.` |
| `2017-08-28_node-js-performance.md` | `[javascript, performance]` | `A real-world benchmark compares Webpack build performance across Node.js 6.11.2, 8.2.1, and 8.4.0.` |
| `2018-01-25_synology-lets-encrypt.md` | `[lets-encrypt, networking]` | `How to resolve Synology DSM Let's Encrypt port 80 errors caused by IPv6 in a dual-stack network.` |
| `2018-02-03_edgerouter-vlan-isolation.md` | `[edgerouter, networking]` | `A step-by-step EdgeRouter guide to creating a VLAN and isolating it from local networks and router services.` |
| `2018-02-07_edgerouter-entertaintv.md` | `[edgerouter, networking]` | `Anleitung für Telekom EntertainTV mit EdgeRouter und UniFi einschließlich IGMP Proxy, Firewall und Multicast.` |
| `2018-02-10_nginx-reverse-proxy-on-raspberry-pi.md` | `[lets-encrypt, linux, networking]` | `A guide to running an nginx reverse proxy on a Raspberry Pi with Let's Encrypt certificates and automatic renewal.` |
| `2018-02-18_how-to-use-wireshark-with-an-edgerouter.md` | `[edgerouter, networking]` | `Monitor EdgeRouter interfaces remotely by piping tcpdump captures over SSH directly into Wireshark.` |
| `2018-02-23_webcodr.io.md` | `[site-news]` | `An announcement of the blog's move from webcodr.de to webcodr.io, including the temporary redirect period.` |
| `2018-02-28_telekom-edgerouter-mtu-mss-clamping.md` | `[edgerouter, networking, vdsl]` | `MSS-Clamping für IPv4 und IPv6 behebt TLS- und Verbindungsprobleme auf EdgeRoutern an Telekom-VDSL-Anschlüssen.` |
| `2018-04-19_wildcard-certificates-lets-encrypt-cloudflare.md` | `[lets-encrypt, web-development]` | `Create and renew Let's Encrypt wildcard certificates automatically with acme.sh, DNS challenges, and the Cloudflare API.` |

Add each row using the same two-line YAML format from Task 1.

- [ ] **Step 4: Run the regression check and verify GREEN**

Run: `bash tests/blog-discovery.sh`

Expected: `Blog discovery checks passed.`

- [ ] **Step 5: Commit the infrastructure batch**

```bash
git add tests/blog-discovery.sh \
  content/post/2017-01-07_vdsl-vigor-130-edgerouter.md \
  content/post/2017-01-07_vodafone-zu-telekom.md \
  content/post/2017-01-09_webpack-2-setup.md \
  content/post/2017-01-15_edgerouter-x-vs-mikrotik-hex.md \
  content/post/2017-08-28_node-js-performance.md \
  content/post/2018-01-25_synology-lets-encrypt.md \
  content/post/2018-02-03_edgerouter-vlan-isolation.md \
  content/post/2018-02-07_edgerouter-entertaintv.md \
  content/post/2018-02-10_nginx-reverse-proxy-on-raspberry-pi.md \
  content/post/2018-02-18_how-to-use-wireshark-with-an-edgerouter.md \
  content/post/2018-02-23_webcodr.io.md \
  content/post/2018-02-28_telekom-edgerouter-mtu-mss-clamping.md \
  content/post/2018-04-19_wildcard-certificates-lets-encrypt-cloudflare.md
git commit -m "content: classify infrastructure posts"
```

### Task 3: Backfill Development and Hardware Posts

**Files:**
- Modify: `tests/blog-discovery.sh`
- Modify: the 11 post files listed in the table below

- [ ] **Step 1: Add failing metadata assertions for this batch**

Add one `assert_post_metadata "FILENAME"` call for every filename in the Task 3 table after the Task 2 calls.

- [ ] **Step 2: Run the regression check and verify RED**

Run: `bash tests/blog-discovery.sh`

Expected: FAIL on `2018-04-22_pimp-your-vscode.md` because its metadata is missing.

- [ ] **Step 3: Add the exact curated metadata**

| File | Topics | Description |
|---|---|---|
| `2018-04-22_pimp-your-vscode.md` | `[developer-tools]` | `A curated collection of Visual Studio Code extensions, themes, and icons for a more productive and polished editor.` |
| `2018-04-24_vue-loader-setup-in-webpack.md` | `[javascript, web-development]` | `Set up vue-loader manually in Webpack, add Vue entry points, and split dependencies into dedicated vendor chunks.` |
| `2018-04-25_Testing-on-steroids-Vue-and-Jest.md` | `[javascript, testing]` | `Configure Jest for Vue components and test asynchronous Fetch behavior with mocks, shallow rendering, and async/await.` |
| `2018-04-27_introducing-delivery-guy.md` | `[javascript, web-development]` | `DeliveryGuy wraps the Fetch API to reject HTTP errors and provide convenient access to response bodies and metadata.` |
| `2018-04-27_why-custom-errors-in-javascript-are-broken.md` | `[javascript, programming]` | `Learn why Babel-transpiled custom JavaScript errors lose inheritance in ES5 and what limited workarounds remain.` |
| `2018-06-13_snapshot-tests-with-jest.md` | `[javascript, testing]` | `Use Jest snapshots to compare serialized output, handle generated values, update snapshots, and avoid common testing mistakes.` |
| `2019-09-25_hello-dark-mode.md` | `[javascript, web-development]` | `Implement automatic dark mode with prefers-color-scheme, matchMedia, and CSS custom properties backed by SCSS.` |
| `2019-10-07_catalina-edid-override.md` | `[hardware, macos]` | `Restore correct HDMI colors in macOS Catalina by installing a patched EDID override from Recovery Mode.` |
| `2020-08-29_kotest-and-junit-with-intellij.md` | `[developer-tools, kotlin, testing]` | `Combine Kotest, MockK, and JUnit 5 in IntelliJ, and fix missing test discovery by adding the Jupiter engine.` |
| `2020-10-31_webcodr-goes-netlify-cms.md` | `[developer-tools, web-development]` | `Add Netlify CMS to a Hugo site for a Git-based publishing workflow that works across desktop and iPad.` |
| `2020-11-18_ryzen-vs-apple-silicon-and-why-zen-2-is-not-so-bad-as-you-may-think.md` | `[hardware, performance]` | `Compare Ryzen Zen 3 and Apple M1 efficiency through chiplets, process nodes, core design, and instruction sets.` |

Add each row using the same two-line YAML format from Task 1.

- [ ] **Step 4: Run the regression check and verify GREEN**

Run: `bash tests/blog-discovery.sh`

Expected: `Blog discovery checks passed.`

- [ ] **Step 5: Commit the development batch**

```bash
git add tests/blog-discovery.sh \
  content/post/2018-04-22_pimp-your-vscode.md \
  content/post/2018-04-24_vue-loader-setup-in-webpack.md \
  content/post/2018-04-25_Testing-on-steroids-Vue-and-Jest.md \
  content/post/2018-04-27_introducing-delivery-guy.md \
  content/post/2018-04-27_why-custom-errors-in-javascript-are-broken.md \
  content/post/2018-06-13_snapshot-tests-with-jest.md \
  content/post/2019-09-25_hello-dark-mode.md \
  content/post/2019-10-07_catalina-edid-override.md \
  content/post/2020-08-29_kotest-and-junit-with-intellij.md \
  content/post/2020-10-31_webcodr-goes-netlify-cms.md \
  content/post/2020-11-18_ryzen-vs-apple-silicon-and-why-zen-2-is-not-so-bad-as-you-may-think.md
git commit -m "content: classify development posts"
```

### Task 4: Complete Recent Metadata

**Files:**
- Modify: `tests/blog-discovery.sh`
- Modify: the 12 post files listed in the table below

- [ ] **Step 1: Add failing metadata assertions for this batch**

Add one `assert_post_metadata "FILENAME"` call for every filename in the Task 4 table after the Task 3 calls.

- [ ] **Step 2: Run the regression check and verify RED**

Run: `bash tests/blog-discovery.sh`

Expected: FAIL on `2021-01-21_real-world-performance-of-the-apple-m1-in-software-development.md` because its metadata is missing.

- [ ] **Step 3: Add topics and descriptions to the 2021–2023 posts**

| File | Topics | Description |
|---|---|---|
| `2021-01-21_real-world-performance-of-the-apple-m1-in-software-development.md` | `[hardware, performance]` | `Real-world build and test benchmarks compare an M1 MacBook Air with Intel and AMD development machines.` |
| `2023-05-15_terminal-evolved.md` | `[developer-tools, linux]` | `A practical introduction to building a productive terminal workflow with Kitty, tmux, and Neovim.` |
| `2023-05-26_introducing-server-runner.md` | `[developer-tools, rust]` | `Server Runner starts configured services, waits until they are ready, runs a command, and cleans up afterward.` |
| `2023-05-27_us-international-keyboard-layout-without-dead-keys.md` | `[hardware]` | `Create and install a Windows US International keyboard layout that supports special characters without dead keys.` |

Add each row using the same two-line YAML format from Task 1.

- [ ] **Step 4: Add descriptions while preserving existing topics exactly**

| File | Existing topics to preserve | Description to add |
|---|---|---|
| `2024-01-19_micro-dsl-kotlin.md` | `[programming, kotlin]` | `Use Kotlin lambdas with receivers to turn conventional builders into concise, readable, and extensible micro DSLs.` |
| `2024-03-06_cli-tools.md` | `[developer-tools, rust]` | `A collection of modern command-line tools for faster navigation, search, shell history, monitoring, and dotfile management.` |
| `2024-10-07_pop-os-bluetooth-handsfree-mode.md` | `[linux]` | `Disable Bluetooth hands-free profiles in WirePlumber to restore high-quality A2DP audio on Ubuntu-based Linux systems.` |
| `2025-05-28_java-switch-dont-do-this.md` | `[programming, kotlin]` | `A subtle Java switch fall-through shows why deeply nested control flow can cause bugs during Kotlin migrations.` |
| `2025-08-01_i-m-using-arch-btw.md` | `[linux, omarchy]` | `An introduction to Omarchy's developer-focused Arch Linux setup, Hyprland defaults, applications, and customization options.` |
| `2025-08-29_more-awesome-cli-tools.md` | `[developer-tools]` | `More useful terminal tools for monitoring systems, inspecting Git changes, querying DNS, counting code, and managing processes.` |
| `2025-10-29_hyprland-trackpad-tips---tricks.md` | `[linux, omarchy]` | `Configure Hyprland trackpad clicks, tapping, natural scrolling, and typing protection for a more comfortable laptop experience.` |
| `2025-10-31_fix-omarchy-gaming--vulkan-.md` | `[linux, omarchy]` | `Fix silently crashing Steam and Proton games on Radeon-based Omarchy systems by installing the missing Vulkan packages.` |

Add only the `description` line from each row. Do not rewrite the existing `topics` line.

- [ ] **Step 5: Run the regression check and verify GREEN**

Run: `bash tests/blog-discovery.sh`

Expected: `Blog discovery checks passed.`

- [ ] **Step 6: Commit the recent-post batch**

```bash
git add tests/blog-discovery.sh \
  content/post/2021-01-21_real-world-performance-of-the-apple-m1-in-software-development.md \
  content/post/2023-05-15_terminal-evolved.md \
  content/post/2023-05-26_introducing-server-runner.md \
  content/post/2023-05-27_us-international-keyboard-layout-without-dead-keys.md \
  content/post/2024-01-19_micro-dsl-kotlin.md \
  content/post/2024-03-06_cli-tools.md \
  content/post/2024-10-07_pop-os-bluetooth-handsfree-mode.md \
  content/post/2025-05-28_java-switch-dont-do-this.md \
  content/post/2025-08-01_i-m-using-arch-btw.md \
  content/post/2025-08-29_more-awesome-cli-tools.md \
  content/post/2025-10-29_hyprland-trackpad-tips---tricks.md \
  content/post/2025-10-31_fix-omarchy-gaming--vulkan-.md
git commit -m "content: complete recent post descriptions"
```

### Task 5: Add Collection-Wide Metadata Coverage

**Files:**
- Modify: `tests/blog-discovery.sh`

- [ ] **Step 1: Replace per-file calls with a collection-wide loop**

Remove all individual `assert_post_metadata` calls added in Tasks 1–4 and add this loop in their place:

```bash
for post in "$root"/content/post/*.md; do
	[[ "$(basename "$post")" == "_index.md" ]] && continue
	assert_post_metadata "$(basename "$post")"
done
```

This checks all 54 regular posts, including the two July 2026 posts whose existing descriptions must remain unchanged.

- [ ] **Step 2: Assert representative older posts appear on topic pages**

Add this helper after `assert_contains()` so assertions can cover paginated topic output:

```bash
assert_tree_contains() {
	grep -RFq -- "$2" "$1" || fail "expected $1 to contain: $2"
}
```

Add these generated-output assertions after the existing topic checks:

```bash
assert_tree_contains "$output/topics/networking" 'VDSL via Vigor 130 und EdgeRouter X'
assert_tree_contains "$output/topics/javascript" 'Snapshot tests with Jest'
assert_tree_contains "$output/topics/hardware" 'Tastaturen'
assert_tree_contains "$output/topics/php" 'Array Almighty'
```

- [ ] **Step 3: Run the complete verification suite**

Run: `bash tests/blog-discovery.sh && hugo`

Expected: `Blog discovery checks passed.` followed by a successful Hugo build with no errors.

- [ ] **Step 4: Review the resulting taxonomy**

Run: `hugo server`

Inspect `/topics/` and representative topic pages for `networking`, `javascript`, `hardware`, and `php`. Confirm topic labels are distinct, older posts are listed with descriptions, and no topic is an accidental spelling variant. Stop the server after review.

- [ ] **Step 5: Confirm existing metadata is unchanged**

Run:

```bash
git diff ba40564 -- content/post/2024-01-19_micro-dsl-kotlin.md content/post/2024-03-06_cli-tools.md content/post/2024-10-07_pop-os-bluetooth-handsfree-mode.md content/post/2025-05-28_java-switch-dont-do-this.md content/post/2025-08-01_i-m-using-arch-btw.md content/post/2025-08-29_more-awesome-cli-tools.md content/post/2025-10-29_hyprland-trackpad-tips---tricks.md content/post/2025-10-31_fix-omarchy-gaming--vulkan-.md content/post/2026-07-05_find-things-even-faster-with-srchr.md content/post/2026-07-05_using-fd-rg-fzf-and-bat-to-find-things-fast.md
```

Expected: For 2024–2025 posts, only one added `description` line per file. For the two July 2026 posts, no diff. Existing `topics` and descriptions are unchanged.

- [ ] **Step 6: Commit collection-wide coverage**

```bash
git add tests/blog-discovery.sh
git commit -m "test: require metadata for every post"
```

### Task 6: Final Verification

**Files:**
- Verify only; no planned modifications

- [ ] **Step 1: Check patch hygiene**

Run: `git diff --check`

Expected: no output and exit status 0.

- [ ] **Step 2: Run fresh regression and build verification**

Run: `bash tests/blog-discovery.sh && hugo`

Expected: `Blog discovery checks passed.` and a successful Hugo build.

- [ ] **Step 3: Inspect repository state**

Run: `git status --short`

Expected: only unrelated pre-existing worktree changes remain; all metadata and metadata-test changes are committed.
