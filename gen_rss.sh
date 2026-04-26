#!/bin/bash

set -euo pipefail
cd "$(dirname "$0")"

FEED_TITLE="Wil's Blog"
FEED_LINK="https://blog.wilsworld.com"
FEED_DESCRIPTION="Some software engineer's blog"
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

cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
    <title>$(xml_escape "$FEED_TITLE")</title>
    <link>$(xml_escape "$FEED_LINK")</link>
    <description>$(xml_escape "$FEED_DESCRIPTION")</description>
    <language>$(xml_escape "$FEED_LANGUAGE")</language>
    <lastBuildDate>$(xml_escape "$FEED_LAST_BUILD_DATE")</lastBuildDate>
    <atom:link href="$(xml_escape "$FEED_LINK")rss.xml" rel="self" type="application/rss+xml" />
EOF

for file in "${files[@]}"; do
    full_path="$SOURCE_DIR/$file"

    date_part="${file%%-*}"
    pub_date=$(to_rfc822 "$date_part")
    if [[ -z "$pub_date" ]]; then
        echo "Warning: Invalid date '$date_part' in file $file, skipping." >&2
        continue
    fi

    title=$(extract_title "$file")
    # Build item link: e.g., FEED_LINK + file without .md => ./YYYY_MM_DD-title
    item_link="${FEED_LINK}${file%.md}"

    # Read file content, escape XML special characters
    # (Read entire file; you may want to limit description length)
    content=$(cat "$full_path")
    escaped_content=$(xml_escape "$content")

    # Output RSS item
    cat <<EOF
    <item>
        <title>$(xml_escape "$title")</title>
        <link>$(xml_escape "$item_link")</link>
        <guid>$(xml_escape "$item_link")</guid>
        <pubDate>$pub_date</pubDate>
        <description><![CDATA[${content}]]></description>
    </item>
EOF
done

# End RSS feed
cat <<EOF
</channel>
</rss>
EOF