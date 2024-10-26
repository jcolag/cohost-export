# SPDX-FileCopyrightText: 2024 John Colagioia
#
# SPDX-License-Identifier: GPL-3.0-or-later

# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'kramdown'
require 'time'

def attach(attachments, html)
  attachments.each do |a|
    base = CGI.escape File.basename a['fileURL']
    html.gsub! '{::}', "<audio controls src='assets/#{base}'>Uh-oh!</audio><br>{::}" if a['kind'] == 'audio'
    html.gsub! '{::}', "<img alt='#{a['altText']}' src='assets/#{base}' title='#{a['altText']}'><br>{::}" if a['kind'] == 'image'
  end
  html.gsub! '{::}', ''
end

def add(block, attachments)
  attachments.push block['attachment'] if block['type'] == 'attachment'
  block['attachments'].each { |a| attachments.push a['attachment'] } if block['type'] == 'attachment-row'
end

def process(folder)
  post = JSON.parse File.read File.join(folder, 'post.json')
  md = "# #{post['headline']}\n\n{::}\n\n"
  attachments = []

  post['blocks'].each do |b|
    md << "#{b['markdown']['content']}\n\n" if b['type'] == 'markdown'
    add(b, attachments)
  end

  md.gsub! "# \n\n", ''
  html = Kramdown::Document.new(md).to_html.gsub 'fn:', "fn:#{post['postId']}:"
  [html, attachments, post['postId'], post['publishedAt'], post['cws'], post['tags'], post['singlePostPageUrl']]
end

html = File.read './head.html'
pages = []

Dir.glob("#{ARGV[0]}/*").select { |f| File.directory?(f) }.each do |d|
  Dir.glob("#{d}/*").reject { |f| f.end_with? '.json' }.each { |f| FileUtils.cp f, '../assets' }
  page, attachments, id, date, cws, tags, url = process d
  attach attachments, page
  pages.push [page, id, date, cws, tags, url]
end

pages.sort_by! { |p| p[2] }.each do |p|
  time = DateTime.parse p[2].to_s
  tt = time.strftime '%A, %Y %B %d, %I:%M:%S %p %Z'
  html << "<div class='post' id='post-#{p[1]}'><a class='cohost-link' href='#{p[5]}'><time class='dt-published' datetime='#{p[2]}'>#{tt}</time></a>"
  p[3].each { |cw| html << "<div class='cw'>⚠️ #{cw} ⚠️</div>" }
  html << '<div class="contents">'
  html << p[0]
  html << '</div>'
  html << '<h2>Tags</h2><ul class="tags">' unless p[4].empty?
  p[4].each { |tag| html << "<li class='tag'>#{tag}</li>" }
  html << '</ul>' unless p[4].empty?
  html << '</div>'
end

foot = File.read './foot.html'
html << foot
puts html
