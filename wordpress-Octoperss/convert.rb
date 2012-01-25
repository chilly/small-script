#本类实现汉字转拼音功能，由perl的Lingua::Han::PinYin包port而来(包括UniHan的数据)。
#
#由于实际需要只实现utf-8版本，需要gbk等转拼音的请使用Iconv自行转换。
# 
#感谢Lingua::Han::PinYin原作者(http://www.fayland.org/journal/Han-PinYin.html)的工作.
#
#Author::    H.J.Leochen ( http://www.upulife.com )
#License::   Distributes under the same terms as Ruby

require 'singleton'
class PinYin
  include Singleton
	#单例模式，使用 PinYin.instance 实例。
	def initialize
		fn = File.join(File.dirname(File.expand_path(__FILE__)),'dict/Mandarin.dat')
		@codes = {}
		File.readlines(fn).each do |line|
			nv = line.split(/\s/)
			@codes[nv[0]] = nv[1]
		end
	end

	#permlink固定分隔符,
	#结果样式：Interesting-Ruby-Tidbits-That-Dont-Need-Separate-Posts-17
	#
	def to_permlink(str)
		str_to_pinyin(str,'-')
	end

	#全部取首字母。 eg. ldh 刘德华
	def to_pinyin_abbr(str)
		str_to_pinyin(str,'',false,true)
	end

	#第一个字取全部，后面首字母.名称缩写。eg. liudh 刘德华
	def to_pinyin_abbr_else(str)
		str_to_pinyin(str,'',true,nil) #后面那个参数已经没有影响了。
	end

	#通用情况 tone为取第几声的标识。eg. ni3hao3zhong1guo2
	def to_pinyin(str,separator='',tone=false)
		str_to_pinyin(str,separator,false,false,tone)
	end

	def get_value(code)
		@codes[code]
	end

	def str_to_pinyin(str,separator='',abbr_else=false,abbr=false,tone=false)
		res = []
		str.unpack('U*').each_with_index do |t,idx|
			code = sprintf('%x',t).upcase
			val = get_value(code)
			#是否找到拼音？
			if val
				unless tone
					val = val.gsub(/\d/,'')
				end
				if (abbr and !abbr_else) or (abbr_else and idx!=0)
					val = val[0..0]
				end
				res << val.downcase+separator
			else
				tmp = [t].pack('U*')
				res << tmp if tmp =~ /^[_0-9a-zA-Z\s]*$/ #复原，去除特殊字符,如全角符号等。
				##???? 为什么 \W 不行呢？非要用0-9a-zA-Z呢？
			end
		end
		unless separator==''
			re = Regexp.new("\\#{separator}+")
			re2 = Regexp.new("\\#{separator}$")
			return res.join('').gsub(/\s+/,separator).gsub(re,separator).gsub(re2,'')
		else
			return res.join('')
		end
	end
end

require 'fileutils'
require 'date'
require 'yaml'
require 'rexml/document'
require 'ya2yaml'
require 'cgi'
include REXML

doc = Document.new(File.new(ARGV[0]))
dirname = "_XXposts"
FileUtils.rmdir dirname
FileUtils.mkdir_p dirname
pinyin = PinYin.instance()
doc.elements.each("rss/channel/item[wp:status = 'publish' and wp:post_type = 'post']") do |e|
  p e.elements['wp:post_name'].text
  post = e.elements
  wordpress_id = post['wp:post_id'].text
  slug = post['wp:post_name'].text
  if slug.include? '%'
    puts slug
    slug = CGI::unescape(slug)
    puts 'convert slug==>' + slug
    slug = pinyin.str_to_pinyin(slug,'-')
    puts 'convert to pinyin ==>' + slug   
  end 
  #slug = wordpress_id
  date = DateTime.parse(post['wp:post_date'].text)
  name = "%02d-%02d-%02d-%s.markdown" % [date.year, date.month, date.day, slug]
  date_string = "#{date.year}-#{date.month}-#{date.day}"
  title_string = post['title'].text

  # convert all tags and categories into categories
  categories = []
  post.each('category') do |cat|
    categories << cat.attributes['nicename']
  end
  puts categories
  
  link = post['link'].text
  link = link.split('?')[0]
  content = post['content:encoded'].text.encode("UTF-8")

  # convert <code></code> blocks to {% codeblock %}{% encodebloc %}
  #content = content.gsub(/<code>(.*?)<\/code>/, '`\1`')
  content = content.gsub(/<code>/, '{% codeblock %}')
  content = content.gsub(/<\/code>/, '{% endcodeblock %}')

  # convert <pre></pre> blocks to {% codeblock %}{% encodebloc %}
  #content = content.gsub(/<pre lang="([^"]*)">(.*?)<\/pre>/m, '`\1`')
  content = content.gsub(/<pre>/, '{% codeblock %}')
  content = content.gsub(/<pre lang="([^"]*)">/, '{% codeblock %}')
  content = content.gsub(/<\/pre>/m, '{% endcodeblock %}')
  # delete syntex 
  content = content.gsub(/\[codesyntax\]/, "")
  content = content.gsub(/\[codesyntax lang="([^"]*)"\]/, "")
  content = content.gsub(/\[\/codesyntax\]/m, "")
  # convert headers
  (1..3).each do |i|
    content = content.gsub(/<h#{i}>([^<]*)<\/h#{i}>/, ('#'*i) + ' \1')
  end

  puts "Converting: #{name}"

  data = {
    'layout' => 'post',
    'title' => post['title'].text,
    'date' => date_string,
    'comments' => true,
    'categories' => categories,
  }.delete_if { |k,v| v.nil? || v == ''}.to_yaml

  File.open("#{dirname}/#{name}", "w") do |f|
    f.puts "---"
    f.puts "layout: post"
    f.puts "title: \"#{title_string}\""
    f.puts "date: #{date_string}"
    f.puts "wordpress_id: #{wordpress_id}"
    f.puts "comments: true"
    f.puts "categories: #{categories}"
    #f.puts data
    f.puts "---"
    post.each('wp:postmeta') do |meta|
    
      key = meta.elements["wp:meta_key"].text
      value = meta.elements["wp:meta_value"].text
      puts key , value
      f.puts "<meta name=\"#{key}\" content=\"#{value}\" />"
    end

    f.puts content
  end

end

