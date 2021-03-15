#!/usr/bin/env ruby

# Open file
quote = File.read('/tmp/quote-process')

# Replace various quotation marks and dashes/hyphens
replacements = [['“', '``'],
                ['”', "''"],
                ['‘', "'"],
                ['’', "'"],
                ['–', '-'],
                ['—', '—']]

replacements.each do |replacement|
  quote.gsub!(replacement[0], replacement[1])
end

# Replace line-continuation hyphens with empty string
regex = /(-\s+)/ # Hyphens with trailing whitespace
quote.gsub!(regex, '')

# Add in LaTeX-style leading and trailing quotation marks.
quote = "``#{quote}''"

# Write out
File.open('/tmp/quote-process', 'w') { |file| file.write(quote) }

