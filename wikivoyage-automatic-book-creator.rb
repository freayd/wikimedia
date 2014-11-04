#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'nokogiri'

article_types    = %w[continent country region city district park airport itinerary diveguide phrasebook topic]
article_statuses = %w[stub outline usable guide star]

# TODO Use a config file instead
dump_path = File.join(File.dirname(__FILE__), 'enwikivoyage-latest-pages-articles.xml')

# Collect informations (type, status, parent and redirections) for every article
puts 'Loading file...'
counter = 0
articles = Hash.new { |hash, key| hash[key] = { type: nil, status: nil, parent: nil, children: [] } }
Nokogiri::XML(File.open(dump_path)).css('page').each do |article|
    puts "#{counter.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/,'\\1 ').rjust(7)} pages processed" if counter % 5000 == 0
    counter += 1

    title = article.at_css('title').content
    text  = article.at_css('text').content
    next if text.match(/\{\{\s*disamb\s*\}\}/i)

    # WARNING This method for storing redirections has it's limits.
    # It implies that element are never assigned again - http://stackoverflow.com/a/15914209
    # Another solution is to create a custom Hash subclass - http://stackoverflow.com/a/15914313
    if redirect = (article.at_css('redirect') || {})['title']
        articles[redirect]
        articles[title] = articles[redirect]
        next
    end

    tag_found = false
    article_types.map do |a_type|
        article_statuses.map do |a_status|
            if tag = text.match(/\{\{\s*(?<status>#{a_status})(?<type>#{a_type})\s*\}\}/i)
                articles[title][:type]   = tag[:type]
                articles[title][:status] = tag[:status]
                tag_found = true
                break
            end
        end
        break if tag_found
    end

    if parent = (text.match(/\{\{IsPartOf\s*\|\s*([\w ,_\-]+)\s*\}\}/i) || [])[1]
        articles[title][:parent] = parent
        articles[parent][:children] << title
    end
end

# TODO Find all articles that have the required parent/grandparent

# TODO Build a smart table of contents

