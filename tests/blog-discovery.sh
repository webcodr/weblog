#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
output=$(mktemp -d)
trap 'rm -rf "$output"' EXIT

fail() {
	printf 'FAIL: %s\n' "$1" >&2
	exit 1
}

assert_file() {
	[[ -f "$1" ]] || fail "expected file $1"
}

assert_not_file() {
	[[ ! -e "$1" ]] || fail "expected no file at $1"
}

assert_contains() {
	grep -Fq -- "$2" "$1" || fail "expected $1 to contain: $2"
}

assert_not_contains() {
	if grep -Fq -- "$2" "$1"; then
		fail "expected $1 not to contain: $2"
	fi
}

assert_count() {
	local actual
	actual=$(grep -Fc -- "$3" "$1")
	[[ "$actual" -eq "$2" ]] || fail "expected $1 to contain $2 occurrences of: $3 (found $actual)"
}

assert_post_metadata() {
	local post="$root/content/post/$1"
	grep -Eq '^topics: \[[a-z0-9-]+(, [a-z0-9-]+){0,2}\]$' "$post" || fail "expected 1-3 normalized topics in $post"
	grep -Eq '^description: .+[.!?]$' "$post" || fail "expected a punctuated description in $post"
}

hugo --source "$root" --destination "$output" --quiet

assert_file "$output/topics/index.xml"
assert_file "$output/topics/developer-tools/index.xml"
assert_contains "$output/topics/index.html" '<h1 class="post-headline">Topics</h1>'
assert_contains "$output/topics/index.html" '>Developer Tools<'
assert_contains "$output/topics/developer-tools/index.html" 'Find things even faster with srchr'
assert_contains "$output/topics/developer-tools/index.html" 'A cross-platform Rust TUI'
assert_file "$output/archive/index.html"
assert_contains "$output/archive/index.html" '<h2 class="archive-year">2026</h2>'
assert_contains "$output/archive/index.html" 'Find things even faster with srchr'
assert_contains "$output/archive/index.html" '<h2 class="archive-year">2012</h2>'

srchr="$output/2026/07/find-things-even-faster-with-srchr/index.html"
search_post="$output/2026/07/using-fd-rg-fzf-and-bat-to-find-things-fast/index.html"
arch_post="$output/2025/08/im-using-arch-btw/index.html"

assert_contains "$srchr" 'Published <time datetime="2026-07-05T20:28:50Z"'
assert_contains "$srchr" '>Developer Tools</a>'
assert_not_contains "$srchr" 'Updated <time'
assert_not_contains "$srchr" 'class="table-of-contents"'
assert_contains "$search_post" 'class="table-of-contents"'
assert_contains "$search_post" 'href="#usage"'
assert_contains "$arch_post" 'Updated <time datetime="2025-08-28T00:00:00Z"'

legacy_post="$output/2018/04/vue-loader-setup-in-webpack/index.html"

assert_contains "$srchr" 'class="related-posts"'
assert_contains "$srchr" 'Using fd, rg, fzf and bat to find things fast'
assert_contains "$srchr" 'class="post-navigation"'
assert_contains "$srchr" 'class="post-navigation-previous"'
assert_not_contains "$srchr" 'class="post-navigation-next"'
assert_contains "$legacy_post" 'class="related-posts"'
assert_contains "$legacy_post" 'class="post-navigation"'
assert_not_contains "$root/themes/webcodr/layouts/partials/post-navigation.html" '&larr;'
assert_not_contains "$root/themes/webcodr/layouts/partials/post-navigation.html" '&rarr;'

home="$output/index.html"

assert_contains "$home" 'class="header-navigation"'
assert_contains "$home" 'href="/topics/"'
assert_contains "$home" 'href="/archive/"'
assert_contains "$home" 'Inspired by my last post about'
assert_contains "$home" 'rel="alternate" type="application/rss&#43;xml"'
assert_count "$home" 5 '<article class="post">'
assert_contains "$output/topics/index.html" 'class="topic-list"'
assert_contains "$output/archive/index.html" 'class="post-index"'
assert_not_file "$output/archive/page/2/index.html"
assert_not_file "$output/topics/page/2/index.html"
assert_not_file "$output/topics/developer-tools/page/2/index.html"
assert_not_file "$output/404/page/2/index.html"
assert_count "$root/assets/css/webcodr.css" 2 'font-family: Roboto, Helvetica, Arial, sans-serif;'
assert_contains "$root/assets/css/webcodr.css" 'a[href]:hover,'
assert_contains "$root/assets/css/webcodr.css" 'a[href]:focus-visible {'
assert_count "$root/assets/css/webcodr.css" 4 'text-decoration: underline;'
assert_not_contains "$root/assets/css/webcodr.css" 'border-bottom: 2px solid var(--post-text-color);'
assert_not_contains "$root/assets/css/webcodr.css" '.related-posts-list,'
assert_contains "$root/assets/css/webcodr.css" '.related-posts-list {'
assert_contains "$root/assets/css/webcodr.css" 'padding-inline: 0;'
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
assert_post_metadata "2017-01-07_vdsl-vigor-130-edgerouter.md"
assert_post_metadata "2017-01-07_vodafone-zu-telekom.md"
assert_post_metadata "2017-01-09_webpack-2-setup.md"
assert_post_metadata "2017-01-15_edgerouter-x-vs-mikrotik-hex.md"
assert_post_metadata "2017-08-28_node-js-performance.md"
assert_post_metadata "2018-01-25_synology-lets-encrypt.md"
assert_post_metadata "2018-02-03_edgerouter-vlan-isolation.md"
assert_post_metadata "2018-02-07_edgerouter-entertaintv.md"
assert_post_metadata "2018-02-10_nginx-reverse-proxy-on-raspberry-pi.md"
assert_post_metadata "2018-02-18_how-to-use-wireshark-with-an-edgerouter.md"
assert_post_metadata "2018-02-23_webcodr.io.md"
assert_post_metadata "2018-02-28_telekom-edgerouter-mtu-mss-clamping.md"
assert_post_metadata "2018-04-19_wildcard-certificates-lets-encrypt-cloudflare.md"
assert_post_metadata "2018-04-22_pimp-your-vscode.md"
assert_post_metadata "2018-04-24_vue-loader-setup-in-webpack.md"
assert_post_metadata "2018-04-25_Testing-on-steroids-Vue-and-Jest.md"
assert_post_metadata "2018-04-27_introducing-delivery-guy.md"
assert_post_metadata "2018-04-27_why-custom-errors-in-javascript-are-broken.md"
assert_post_metadata "2018-06-13_snapshot-tests-with-jest.md"
assert_post_metadata "2019-09-25_hello-dark-mode.md"
assert_post_metadata "2019-10-07_catalina-edid-override.md"
assert_post_metadata "2020-08-29_kotest-and-junit-with-intellij.md"
assert_post_metadata "2020-10-31_webcodr-goes-netlify-cms.md"
assert_post_metadata "2020-11-18_ryzen-vs-apple-silicon-and-why-zen-2-is-not-so-bad-as-you-may-think.md"
assert_post_metadata "2021-01-21_real-world-performance-of-the-apple-m1-in-software-development.md"
assert_post_metadata "2023-05-15_terminal-evolved.md"
assert_post_metadata "2023-05-26_introducing-server-runner.md"
assert_post_metadata "2023-05-27_us-international-keyboard-layout-without-dead-keys.md"
assert_post_metadata "2024-01-19_micro-dsl-kotlin.md"
assert_post_metadata "2024-03-06_cli-tools.md"
assert_post_metadata "2024-10-07_pop-os-bluetooth-handsfree-mode.md"
assert_post_metadata "2025-05-28_java-switch-dont-do-this.md"
assert_post_metadata "2025-08-01_i-m-using-arch-btw.md"
assert_post_metadata "2025-08-29_more-awesome-cli-tools.md"
assert_post_metadata "2025-10-29_hyprland-trackpad-tips---tricks.md"
assert_post_metadata "2025-10-31_fix-omarchy-gaming--vulkan-.md"

printf 'Blog discovery checks passed.\n'
