#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'mediawiki_api'

wikivoyage_api_url = 'https://en.wikivoyage.org/w/api.php'
malformed_category = 'Category:Pages_with_malformed_coordinate_tags'

client = MediawikiApi::Client.new wikivoyage_api_url

# Iterate over malformed pages
malformed_pages = client.list(:categorymembers, cmtitle: malformed_category).data
malformed_pages.each do |page|
    malformed_coords = []
    page_content = client.get_wikitext(page['title']).body

    # Scan {{listing}} coordinates
    page_content.scan(/\|\s*lat\s*=\s*[^\|]*\|\s*long\s*=\s*[^\|]*\|/i) do |coord|
        malformed_coords << coord unless
                coord =~ /\|\s*lat\s*=\s*\|\s*long\s*=\s*\|/i                          || # Skip empty coordinates
                coord =~ /\|\s*lat\s*=\s*\-?\d+\.\d+\s*\|\s*long\s*=\s*\-?\d+\.\d+\s*\|/i # Skip well-formed coordinates
    end

    # TODO Scan {{geo}} coordinates

    # Show malformed
    puts "========= #{page['title']} ========="
    if malformed_coords.empty?
        puts 'Sorry, could not find the problematic coordinates...'
    else
        puts malformed_coords
    end
    puts
end
