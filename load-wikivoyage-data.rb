require 'active_record'
require_relative 'models/wikivoyage'
require 'active_support'
require 'nokogiri'
require 'yaml'

def open_wikivoyage
    ActiveRecord::Base.establish_connection(YAML::load(File.open('config/wikivoyage-database.yml')))
    ActiveRecord::Base.logger = Logger.new(File.open('db/wikivoyage.log', 'a'))
end

def load_wikivoyage
    open_wikivoyage

    return if WikivoyageArticle.count > 0

    types    = %w[Continent Country Region City District Park Airport Itinerary DiveGuide Phrasebook Topic]
    statuses = %w[Outline Usable Guide Star]

    # TODO Use a config file instead
    dump_path = File.join(File.dirname(__FILE__), 'enwikivoyage-latest-pages-articles.xml')

    # TODO Download dump file

    # Collect informations (type, status, parent and redirections) for every article
    puts 'Loading file...'
    counter = 0
    redirects = {}
    parents = {}
    Nokogiri::XML(File.open(dump_path)).css('page').each do |xml_article|
        puts "#{ActiveSupport::NumberHelper::number_to_delimited(counter, delimiter: ' ').rjust(7)} pages processed" if counter % 5000 == 0 && counter > 0
        counter += 1

        title = xml_article.at_css('title').content
        text  = xml_article.at_css('text').content
        redirect_title = (xml_article.at_css('redirect') || {})['title']
        parent_title   = (text.match(/\{\{IsPartOf\s*\|\s*([\w ,_\-]+)\s*\}\}/i) || [])[1]

        type = status = nil
        if redirect_title
            type = 'Redirect'
        elsif text.match(/\{\{\s*(?:disamb|disambig|disambiguation|dab)\s*\}\}/i)
            type = 'Disambiguation'
        elsif text.match(/\{\{\s*extraregion(?:\s*\|\s*subregion\s*=\s*(?:yes|no))?\s*\}\}/i)
            type = 'ExtraRegion'
        elsif text.match(/\{\{\s*stub\s*\}\}/i)
            type   = 'WikivoyageArticle'
            status = 'Stub'
        else
            types.map do |a_type|
                statuses.map do |a_status|
                    if text.match(/\{\{\s*(?:#{a_status})(?:#{a_type})\s*\}\}/i)
                        type   = a_type
                        status = a_status
                        break
                    end
                end
                break if type
            end
            type = 'WikivoyageArticle' unless type
        end

        article = type.constantize.create(title: title, text: text, status: status)

        if redirect_title
            redirects[article] = redirect_title
        end
        if parent_title
            parents[article] = parent_title
        end
    end

    puts 'Processing redirects...'
    redirects.each do |article, redirect_title|
        article.update(redirect: WikivoyageArticle.find_by(title: redirect_title))
    end

    puts 'Processing parents...'
    parents.each do |article, parent_title|
        article.update(parent: WikivoyageArticle.find_by(title: parent_title))
    end
end
