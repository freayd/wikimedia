require_relative 'common'
require 'active_support/core_ext'
require_relative '../lib/core_ext'

class WikivoyageArticle < Article
    has_many :children, class_name: 'Article',
                        foreign_key: 'parent_id'
    belongs_to :parent, class_name: 'Article'
end

class Continent < WikivoyageArticle
end

class Country < WikivoyageArticle
    def regions
        regions = {}
        append = lambda do |name, article|
            regions[name] = article if article.parent == self &&
                                       !regions.has_value?(article)
        end

        # From the {{Regionlist}} template under the 'Regions' section
        section('Regions').try(:scan, /region(\d+)name\s*=\s*(#{MediaWiki::TEXT_OR_LINK_R})/i) do |id, name|
            label, article = MediaWiki::linked_articles(name, type: Region).to_a.first
            if article
                append.call(label, article)
            else
                # If the region name is not an article, then use the items
                name.strip!
                items = section('Regions').match(/region#{id}items\s*=\s*([^\|\}]+)/i).try('[]', 1) || ''
                MediaWiki::linked_articles(items, type: Region).each do |label, article|
                    append.call("#{name} - #{label}", article)
                end
            end
        end

        # From the 'Regions' section (not in the {{Regionlist}} template)
        MediaWiki::linked_articles(section('Regions'), type: Region).each do |label, article|
            append.call(label, article)
        end

        # From the children articles
        children.to_a.each do |child|
            append.call(child.title, child) if child.class == Region
        end

        regions
    end

    def phrasebooks
        MediaWiki::linked_articles(text, type: Phrasebook)
    end

    def book_contents
        <<-EOS.strip_heredoc(from_first_line: true)
            #{book_chapter('Country')}
            #{phrasebooks.collect { |label, article| article.book_entry }.join($/)}

            #{regions.collect do |label, article|
                article.book_chapter(label)
            end.join($/)}
        EOS
    end
end

class Region < WikivoyageArticle
end

class ExtraRegion < WikivoyageArticle
end

class City < WikivoyageArticle
end

class District < WikivoyageArticle
end

class Park < WikivoyageArticle
end

class Airport < WikivoyageArticle
end

class Itinerary < WikivoyageArticle
end

class DiveGuide < WikivoyageArticle
end

class Phrasebook < WikivoyageArticle
end

class Topic < WikivoyageArticle
end
