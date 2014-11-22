require_relative 'common'
require 'active_support/core_ext'

class WikivoyageArticle < Article
    has_many :children, class_name: 'Article',
                        foreign_key: 'parent_id'
    belongs_to :parent, class_name: 'Article'
end

class Continent < WikivoyageArticle
end

class Country < WikivoyageArticle
    def phrasebooks
        internal_links.collect do |link|
            article = Article.find_by(title: link[:title]).try(:follow_redirect)
            article if article.class == Phrasebook
        end.compact.uniq
    end

    def book_contents
        <<-EOS.gsub(/^\s+/, '')
            ;Country
            #{book_entry}
            #{phrasebooks.collect { |article| article.book_entry }.join($/)}
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
