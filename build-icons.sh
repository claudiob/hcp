#!/bin/sh
# Every icon this gem shows anywhere is rendered from icon.svg, so the door is drawn once
# and the set cannot drift apart: the browser's, iOS', and the avatar GitHub and the social
# networks are given. Run it after editing icon.svg and commit what changes.
#
#   brew install librsvg imagemagick
set -e

png() { rsvg-convert -w "$1" -h "$1" icon.svg -o "$2"; }

# jbr renders its home-screen and avatar icons from an SVG whose tile `rx` has been set to
# 0, since iOS masks a bookmark and every avatar is shown round, and a corner rounded twice
# reads as a mistake. This mark is line art on nothing: there is no tile, so there is no
# corner to unround, and every size renders from the one file.
#
# What transparency costs instead: iOS composites a home-screen icon onto black and GitHub
# shows an avatar against either theme, so those two are the ones that get a white page
# under them — the same white the manifest names as its background.
white() { png "$1" "$2"; magick "$2" -background white -alpha remove -alpha off "$2"; }

white 180 apple-touch-icon.png

# One avatar for GitHub and for every social network that asks for a picture: each crops
# its own square, and 1024 is the largest any of them wants.
white 1024 avatar.png
png 96 favicon-96x96.png
png 192 web-app-manifest-192x192.png
png 512 web-app-manifest-512x512.png

# One .ico holding three sizes, each a PNG inside it, which is what a browser reaches for
# when it has been given no <link> — and what Windows and older Safari prefer regardless.
for size in 16 32 48; do png "$size" "/tmp/hcp-$size.png"; done
magick /tmp/hcp-16.png /tmp/hcp-32.png /tmp/hcp-48.png favicon.ico
