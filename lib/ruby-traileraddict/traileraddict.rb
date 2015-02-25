class TrailerAddict

  require 'net/http'
  require 'uri'
  require 'hpricot'

  def self.base_api_url
    "http://api.traileraddict.com/"
  end
  
  def self.base_search_url
    "http://www.traileraddict.com/search.php?q="
  end
  
  def self.imdb_search_url
    "http://api.traileraddict.com/?imdb="    
  end
  
  def self.get_tag_for(movie_name)
    response = self.get_url(self.base_search_url + URI.escape(movie_name))
    return nil if(response.code != '200')
    search_page_object = Hpricot( response.body )
    return nil if( search_page_object.search(".leftcolumn .searchthumb:first a")[0].nil? )
    tag = search_page_object.search(".leftcolumn .searchthumb:first a")[0]['href'].gsub("/tags/", '')
  end
  
  def self.get_tag_for_imdb(imdbid)
    response = self.get_url(self.imdb_search_url + imdbid)
    return nil if(response.code != '200')
    search_page_object = Hpricot( response.body )
    return nil if( search_page_object.search(".leftcolumn .searchthumb:first a")[0].nil? )
    tag = search_page_object.search(".leftcolumn .searchthumb:first a")[0]['href'].gsub("/tags/", '')
  end
  
  def self.api_call(movie_tag, options={})
    raise ArgumentError, "movie_tag must be a string" unless(movie_tag.is_a?(String))
    options = {
      :count => 1,
      :trailers => :yes,
      :film => movie_tag
    }.merge(options)
    option_string = "?" + URI.escape(options.to_a.map{|x| x[0].to_s + "=" + x[1].to_s}.join("&"))
    response = self.get_url(self.base_api_url + option_string)
    if(response.code == '200')
      return response.body  
    else
      return ''
    end
  end
  def self.imdb_api_call(imdbid,options={})
     raise ArgumentError, "movie_tag must be a string" unless(imdbid.is_a?(Integer))
       options = {
         :width=> "000",
         :count=>10,
         :imdb => imdbid
       }.merge(options)
       option_string = "?" + URI.escape(options.to_a.map{|x| x[0].to_s + "=" + x[1].to_s}.join("&"))
       response = self.get_url(self.base_api_url + option_string)
       if(response.code == '200')
         return response.body  
       else
         return ''
       end
    
  end
  
  def self.get_trailer_by_imdb(imdbid)
   api_response = self.imdb_api_call(imdbid)
    xml = Hpricot::XML( api_response )
    embed_codes = xml.search("embed")
    resp=Array.new
    embed_codes.each do |e|
      resp<<e.inner_text
    end
    
    return nil if( resp.size < 1 )
    return resp
    
  end
  
  
  def self.get_trailer_embed_code(movie_name)
    movie_tag = self.get_tag_for(movie_name)
    api_response = self.api_call(movie_tag)
    xml = Hpricot::XML( api_response )
    embed_code = xml.search("embed")[0].inner_text
    return nil if( embed_code.length < 20 )
    return embed_code
  end
  
  # Get a URL and return a response object, follow upto 'limit' re-directs on the way
  def self.get_url(uri_str, limit = 10)
    return false if limit == 0
    begin 
      response = Net::HTTP.get_response(URI.parse(uri_str))
    rescue SocketError, Errno::ENETDOWN
      response = Net::HTTPBadRequest.new( '404', 404, "Not Found" )
      return response
    end 
    case response
      when Net::HTTPSuccess     then response
      when Net::HTTPRedirection then get_url(response['location'], limit - 1)
    else
      Net::HTTPBadRequest.new( '404', 404, "Not Found" )
    end
  end

end