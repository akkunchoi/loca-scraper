#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require "bundler/setup"

require 'nokogiri'

require 'open-uri'
require 'net/http'
require 'uri'
require 'kconv'
require 'yaml'

String.class_eval do
  def trim
    gsub(/(^(\s|　)+)|((\s|　)+$)/, '')
  end
end

Object.class_eval do
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

class LocaScraper
  def initialize
    @start_url = 'http://loca.ash.jp/indexyear.htm'
    @encoding = 'utf-8'
    @outputfile = 'out.txt'
    @interval = 1
  end
  
  def run
    File.delete(@outputfile)
    
    links(@start_url) do |url|
      if !url.match(/^info/)
        next
      end
      
      url = File.dirname(@start_url) + '/' + url
      
      File.open(@outputfile, "a") do |f|
        info = parse_page(url)
        info[:places].each do |a|
          f.puts info[:name] + "\t" + a.join("\t")
        end
        p info[:name]
        sleep @interval
      end
      end
  end
  #
  # ページ内のリンクを取得
  # 
  def links(url)
    doc = Nokogiri::HTML(open(url, {}).read)
    doc.encoding = @encoding
    
    @links = doc.xpath("//a")
    
    puts "Links = " + @links.size.to_s
    @links.each do |link|
      attr = link.attr('href')
      if !attr.blank?
        yield attr
      end
    end
  end
  
  def parse_page(url)
    doc = Nokogiri::HTML(open(url, {}).read)
    doc.encoding = @encoding

    tables = doc.xpath("//table[not (@class='index')]")
    
    first = tables.shift
    name = first.xpath(".//strong")[0].text()
    
    ret = {:name => name, :places => []}
    tables.each do |table|
      table.xpath(".//td").each do |td|
         ret[:places] << td.text().split("\n").map{|s| s.trim}.reject{|s| s.size == 0}
      end
    end
    
    ret
  end
end
