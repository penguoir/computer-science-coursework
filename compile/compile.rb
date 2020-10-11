require 'redcarpet'
require 'rouge'
require 'rouge/plugins/redcarpet'

# HTML Markdown renderer with SmartyPants
class Renderer < Redcarpet::Render::HTML
  include Redcarpet::Render::SmartyPants
  include Rouge::Plugins::Redcarpet

  @@header_counter = Array.new(6).fill(0)

  def header(text, header_level)
    # Everything after header level goes to 0
    @@header_counter.fill(0, (header_level)..)

    # Increment counter
    @@header_counter[header_level - 1] += 1

    # The list of numbers
    numbers = @@header_counter[0...header_level].join('.') + ' '

    # Create id for TOC
    id = text.downcase.gsub(/ /, '-').gsub(/[^A-Z|a-z|-]/, '')

    %Q(<h#{header_level + 1} id="#{id}">#{numbers + text}</h#{header_level + 1}>)
  end

  def footnote_ref(number)
    %Q([<a href="#fnref#{number}">#{number}</a>])
  end
end

markdown = Redcarpet::Markdown.new(Renderer.new(:with_toc_data => true), {
  :no_intra_emphasis => true, # dont italic this_and_this
  :tables => true,
  :fenced_code_blocks => true,
  :autolink => true, # autolink links in <>
  :space_after_headers => true, # can't do #header
  :superscript => true, # 2^(nd)
  :footnotes => true, # blah blah [^1] ... [^1]: Footnote
  :with_toc_data => true
})

toc = Redcarpet::Markdown.new(Redcarpet::Render::HTML_TOC.new)

# All the documentation files
doc_files = Dir["*.md"]

# Sort the files by their title
doc_files.sort!

# Surround each element with ''
doc_files.map! { |f| "'#{f}'" }

# Append all files to .temp using ">"
`cat #{doc_files.join(' ')} > .temp`

# Delete specification lines using "sed"
`sed '/STARTSPEC/,/ENDSPEC/d' .temp -i` 

# Read the temp file
content = File.read(".temp")

# Read the CSS file
head = File.read("compile/head.html")

# Add the css, table of contents, and content to an HTML file
File.open('index.html', 'w') do |file|
  file << head
  file << %q(
    <h1 style="text-align: center; text-decoration: underline">
      Building a project-based learning management system
    </h1>
    <div style="display: flex; justify-content: space-between;">
      <p>
        Ori Marash [3024]
      </p>
      <p>
        King Alfred School [12254]<br/>
      </p>
    </div>
  ) 
  file << toc.render(content)
  file << markdown.render(content)
end

# Remove the temporary file
`trash .temp`

# Brag about it
puts "Created report with #{doc_files.length} files."
