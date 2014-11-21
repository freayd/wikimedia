require_relative 'common'

class WikivoyageArticle < Article
    has_many :children, class_name: 'WikivoyageArticle',
                        foreign_key: 'parent_id'
    belongs_to :parent, class_name: 'WikivoyageArticle'
end

class Continent < WikivoyageArticle
end

class Country < WikivoyageArticle
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
