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
    # {
    #   'North' => Region<North of this country>,
    #   'South' => Region<South of this country>,
    #   'Islands' => {
    #                  'Yellow Island' => Region<Yellow Island (this country)>,
    #                  'Mystic Island' => Region<Mystic Island (this country)>
    #                }
    # }
    def regions
        regions_h = {}
        regions_a = []
        append = lambda do |label, sublabel, article|
            if article.parent == self && !regions_a.include?(article)
                if sublabel
                    if regions_h[label]
                        unless regions_h[label].is_a?(Hash)
                            regions_h[label] = { regions_h[label].title => regions_h[label] }
                        end
                    else
                        regions_h[label] = {}
                    end
                    regions_h[label][sublabel] = article
                else
                    regions_h[label] = article
                end
                regions_a << article
            end
        end

        # From the {{Regionlist}} template under the 'Regions' section
        section('Regions').try(:scan, /region(\d+)name\s*=\s*(#{MediaWiki::TEXT_OR_LINK_R})/i) do |id, name|
            label, article = MediaWiki::linked_articles(name, type: Region).to_a.first
            if article
                append.call(label, nil, article)
            else
                # If the region name is not an article, then use the items
                name.strip!
                items = section('Regions').match(/region#{id}items\s*=\s*([^\|\}]+)/i).try('[]', 1) || ''
                MediaWiki::linked_articles(items, type: Region).each do |label, article|
                    append.call(name, label, article)
                end
            end
        end

        # From the 'Regions' section (not in the {{Regionlist}} template)
        MediaWiki::linked_articles(section('Regions'), type: Region).each do |label, article|
            append.call(label, nil, article)
        end

        # From the children articles
        children.to_a.each do |child|
            append.call(child.title, nil, child) if child.is_a?(Region)
        end

        regions_h
    end

    def phrasebooks
        MediaWiki::linked_articles(text, type: Phrasebook)
    end

    def book_contents
        super(regions)
    end

    def book_chapter
        super(title, phrasebooks)
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
