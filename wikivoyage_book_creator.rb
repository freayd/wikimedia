#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require_relative 'load_wikivoyage'

# TODO Use a config file instead
book_root = 'Taiwan'

load_wikivoyage
Article.find_by(title: book_root).book
