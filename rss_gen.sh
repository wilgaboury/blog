#!/bin/bash

set -euo pipefail
cd "$(dirname "$0")"

FEED_TITLE="Wil's Blog"
FEED_LINK="https://blog.wilsworld.net"
FEED_DESCRIPTION="a blog mostly about software engineering"
FEED_LANGUAGE="en-us"
FEED_LAST_BUILD_DATE=$(date -R)
SOURCE_DIR=./src/posts

xml_escape() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    s="${s//\"/&quot;}"
    s="${s//\'/&apos;}"
    printf "%s" "$s"
}

# Convert YYYY_MM_DD to RFC 822 date (e.g., "Sat, 25 Apr 2026 00:00:00 +0000")
# Assumes UTC midnight as the publication time.
to_rfc822() {
    local ymd="$1"
    local y=${ymd%%_*}
    local rest=${ymd#*_}
    local m=${rest%%_*}
    local d=${rest#*_}
    date -u -d "${y}/${m}/${d}" "+%a, %d %b %Y %H:%M:%S +0000" 2>/dev/null
}

extract_title() {
    local filename="$1"
    local base="${filename##*/}"                # remove path
    local title_part="${base#*-}"               # remove YYYY_MM_DD-
    title_part="${title_part%.md}"              # remove .md
    title_part="${title_part//_/ }"             # underscores to spaces
    echo "$title_part"
}

extract_description() {
    echo $(sed -n '3s/^description: *"\([^"]*\)"/\1/p' "$1")
}

cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:content="http://purl.org/rss/1.0/modules/content/">
<channel>
    <title>$FEED_TITLE</title>
    <link>$(xml_escape "$FEED_LINK")</link>
    <description>$(xml_escape "$FEED_DESCRIPTION")</description>
    <language>$(xml_escape "$FEED_LANGUAGE")</language>
    <lastBuildDate>$(xml_escape "$FEED_LAST_BUILD_DATE")</lastBuildDate>
    <atom:link href="$(xml_escape "$FEED_LINK")/rss.xml" rel="self" type="application/rss+xml" />
EOF

for file in "$SOURCE_DIR"/*; do
    filename=$(basename "$file")
    date_part="${filename%%-*}"
    pub_date=$(to_rfc822 "$date_part")
    if [[ -z "$pub_date" ]]; then
        echo "ERROR: Invalid date part '$ymd' in file (expected YYYY_MM_DD)" >&2
        exit 1
    fi

    title=$(extract_title "$file")
    item_link="${FEED_LINK}/posts/${filename%.md}.html"
    description=$(extract_description "$file")
    content=$(cat "./public/posts/${filename%.md}.html")

    # Output RSS item
    cat <<EOF
    <item>
        <title>$(xml_escape "$title")</title>
        <link>$(xml_escape "$item_link")</link>
        <guid>$(xml_escape "$item_link")</guid>
        <pubDate>$pub_date</pubDate>
        <description>$description</description>
        <content:encoded><![CDATA[$content]]></content:encoded>
    </item>
EOF
done

# End RSS feed
cat <<EOF
</channel>
</rss>
EOF