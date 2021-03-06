require_relative '../lib/core_ext'

# MediaWiki markup parser
module MediaWiki
    # _C characters
    # _R regexp
    # _GR greedy regexp
    # _LR lazy   regexp
    TEXT_C = '\p{Alnum} _\-\(\)\.#'
    TEXT_GR = /[#{TEXT_C}]+/
    TEXT_LR = /[#{TEXT_C}]+?/
    INTERNAL_LINK_R = /\[\[\s*([#{TEXT_C}]+)(?:\s*\|\s*([#{TEXT_C}\|]*\s*))?\]\]([a-zA-Z]*)/
    TEXT_OR_LINK_R = /(?:#{TEXT_GR}|#{INTERNAL_LINK_R})/
    SECTION_R = /(?<!=)(==)[ \t]*(#{TEXT_LR})[ \t]*==(?!=)/

    def self.internal_links(text)
        return [] unless text

        links = []
        text.scan(MediaWiki::INTERNAL_LINK_R) do |link|
            title = link[0]
            label = (link[1] || '') + link[2]
            if label.empty?
                label = title
            elsif !label.match(/^\s+$/)
                label.rstrip!
            end
            links << { title: title, label: label }
        end

        links
    end

    def self.linked_articles(text, type: Article)
        self.internal_links(text).each_with_object({}) do |link, articles|
            article = Article.find_by(title: link[:title]).try(:follow_redirect)
            articles[link[:label]] = article if article.is_a?(type) &&
                                                !articles.has_value?(article)
        end
    end
end

class Article < ActiveRecord::Base
    validates :title, presence: true

    def inspect
        title.inspect
    end

    def sections
        s = {}

        lead_section = true
        section_title = nil
        next_is = nil
        text.split(MediaWiki::SECTION_R).each do |t|
            if lead_section
                if t != '=='
                    s[''] = t
                else
                    next_is = :section_title
                end
                lead_section = false
            elsif t == '=='
                next_is = :section_title
            elsif next_is == :section_title
                section_title = t
                next_is = :section_content
            elsif next_is == :section_content
                s[section_title] = t
                next_is = nil
            end
        end
        s
    end

    def section(name)
        sections[name]
    end

    def follow_redirect
        self
    end

    def book(title: self.title, subtitle: nil,
             cover_image: nil, cover_color: nil, cover_text_color: nil,
             paper_size: 'a4', show_table_of_contents: 'auto', columns: 2,
             description: nil, sort_as: nil)
        parameters = {
            # Cover
            'title'       => title,
            'subtitle'    => subtitle,
            'cover-image' => cover_image,
            'cover-color' => cover_color,
            'text-color'  => cover_text_color,
            # Book Creator
            'setting-papersize' => paper_size,
            'setting-toc'       => show_table_of_contents,
            'setting-columns'   => columns,
            # Maintenance
            'description' => description,
            'sort_as'     => sort_as
        }

        <<-EOS.strip_heredoc(from_first_line: true)
            {{saved_book
             | #{ parameters.collect { |k, v| "#{k} = #{v}" if v }.compact.join("#{$/} | ") }
            }}

            == #{title} ==
            #{ "=== #{subtitle} ===#{$/}" if subtitle }
            #{book_contents}

            [[Category:Books|#{title}]]
        EOS
    end

    BookContent = Struct.new(:chapters) do
        def to_s
            chapters.join($/ * 2)
        end
    end
    BookChapter = Struct.new(:parent, :label, :entries) do
        def to_s
            entries_are_chapters = entries.try(:first).is_a?(BookChapter)
            s = ''
            if parent
                s << ";#{parent.label} - #{label}" << $/
            elsif !entries_are_chapters
                s << ";#{label}" << $/
            end
            s + entries.join(entries_are_chapters ? $/ * 2 : $/)
        end
    end
    BookEntry = Struct.new(:label, :article) do
        def to_s
            if label && label != article.title
                ":[[#{article.title}|#{label}]]"
            else
                ":[[#{article.title}]]"
            end
        end
    end

    def book_contents(chapters = {})
        chapters = chapters.collect do |label, article|
            if article.is_a?(Hash)
                parent_chapter = BookChapter.new(nil, label)
                parent_chapter.entries = article.collect do |label, article|
                    child_chapter = article.book_chapter(label)
                    child_chapter.parent = parent_chapter
                    child_chapter
                end
                parent_chapter
            else
                article.book_chapter(label)
            end
        end
        chapters.unshift(book_chapter)
        BookContent.new(chapters)
    end

    def book_chapter(label = nil, entries = {})
        entries = entries.collect { |label, article| article.book_entry(label) }
        entries.unshift(book_entry)
        BookChapter.new(nil, label || title, entries)
    end

    def book_entry(label = nil)
        BookEntry.new(label || title, self)
    end
end

class Disambiguation < Article
end

class Redirect < Article
    belongs_to :redirect, class_name: 'Article'
    validates :redirect, presence: true

    def follow_redirect
        redirect
    end

    def book
        redirect.book
    end

    def book_contents(*args)
        redirect.book_contents(*args)
    end

    def book_chapter(*args)
        redirect.book_chapter(*args)
    end

    def book_entry(*args)
        redirect.book_entry(*args)
    end
end
