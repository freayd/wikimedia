#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require_relative 'load_wikivoyage'

# TODO Use a config file instead
book_root = 'Taiwan'

# Find all articles that have the required parent/grandparent
load_wikivoyage
book_articles = []
find_children = lambda do |article|
    book_articles << article.title
    article.children.each { |child| find_children.call(child) }
end
find_children.call(WikivoyageArticle.find_by(title: book_root))

# TODO Build a smart table of contents

