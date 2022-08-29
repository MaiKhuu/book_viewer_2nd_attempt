# frozen_string_literal: true

require 'tilt/erubis'
require 'sinatra'
require 'sinatra/reloader' if development?

before do
  @toc = File.readlines('data/toc.txt')
  @total_chapters = @toc.count
end

# rubocop:disable Metrics/BlockLength
helpers do
  # break all chapter content into array of <p> tags with numbered id
  def in_paragraph(text)
    id = 0
    text.split("\n\n").map do |para|
      id += 1
      "<p id=paragraph#{id}> #{para} </p>"
    end
  end

  # check if search query is valid (not all white spaces)
  def valid_text?(text)
    return false if text.nil?

    !text.gsub(' ', '').empty?
  end

  # iterate through all chapters content, yield chapter number, name, in_paragraph(content)
  def each_chapter
    (1..@total_chapters).to_a.each do |chp_num|
      chp_content = in_paragraph(File.read("data/chp#{chp_num}.txt"))
      yield chp_num, @toc[chp_num - 1], chp_content
    end
  end

  # iterate through all paragraphs, yield id and paragraph content
  def each_paragraph(all_paragraphs)
    all_paragraphs.each_with_index do |para, index|
      yield "paragraph#{index + 1}", para
    end
  end

  # return hash of chapters number, name, array of paragraphs matching text
  def chapters_matching(text)
    result = []

    each_chapter do |chp_num, chp_title, chp_paragraphs|
      result_paras = []
      each_paragraph(chp_paragraphs) do |para_id, para_content|
        result_paras << { id: para_id, content: para_content } if para_content.include?(text)
      end
      result << { num: chp_num, title: chp_title, matching_paragraphs: result_paras } unless result_paras.empty?
    end

    result
  end

  # returns paragraph with text in <strong> tag
  def paragraph_highlighted(para, text)
    para.gsub(text, "<strong>#{text}</strong>")
  end
end
# rubocop:enable Metrics/BlockLength

get '/' do
  @title = 'The Adventures of Sherlock Holmes'

  erb :home
end

get '/chapters/:number' do
  redirect '/' unless (1..@total_chapters).to_a.include?(params[:number].to_i)

  @title = "Chapter #{params[:number]}: " + @toc[params[:number].to_i - 1]
  @chapter_content = File.read("data/chp#{params[:number]}.txt")

  erb :chapter
end

get '/search' do
  @search_result = chapters_matching(params[:search_query]) if valid_text?(params[:search_query])
  erb :search
end

not_found do
  redirect '/'
end
