require 'active_support/core_ext/object/try'
require 'active_support/core_ext/string/strip'

class String
    def strip_heredoc(from_first_line: false)
        method = from_first_line ? :first : :min
        indent = scan(/^[ \t]*(?=\S)/).send(method).try(:size) || 0
        gsub(/^[ \t]{#{indent}}/, '')
    end
end
