# SPDX-FileCopyrightText: 2024 John Colagioia
#
# SPDX-License-Identifier: GPL-3.0-or-later

# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'kramdown'
require 'time'

def process(file)
  post = JSON.parse File.read file
  md = post['body']
  html = Kramdown::Document.new(md).to_html.gsub 'fn:', "fn:#{post['commentId']}:"
  [html, post['commentId'], post['postedAt'], post['post']]
end

html = File.read './head.html'
pages = []

Dir.glob("#{ARGV[0]}/*").select { |f| !File.directory?(f) }.each do |d|
  page, id, date, url = process d
  pages.push [page, id, date, url]
end

pages.sort_by! { |p| p[2] }.each do |p|
  time = DateTime.parse p[2].to_s
  tt = time.strftime '%A, %Y %B %d, %I:%M:%S %p %Z'
  html << "<div class='post' id='post-#{p[1]}'><a class='cohost-link' href='#{p[3]}'><time class='dt-published' datetime='#{p[2]}'>#{tt}</time></a>"
  html << '<div class="contents">'
  html << p[0]
  html << '</div>'
  html << '</div>'
end

foot = File.read './foot.html'
html << foot
puts html
