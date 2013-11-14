require "twitter"
require_relative "auth_info"

Twitter.configure do |config|
  config.consumer_key = LOGIN[:consumer_key]
  config.consumer_secret = LOGIN[:consumer_secret]
  config.oauth_token = LOGIN[:oauth_token]
  config.oauth_token_secret = LOGIN[:oauth_token_secret]
end

def find_result(status)
  #Splits the message into an array
  prob = status.split(' ')

  #Deletes @Tweetulate　(Assumes this is the first element)
  prob.delete_at(0)

  puts "Received: #{status}"

  #Make sure the proper number elements remain in the array,
  #Assumes correct elements if the length matches
  if prob.length == 3
    sym = prob.delete_at(1).to_sym #Extracts + - % /
    prob[0], prob[1] = prob[0].to_f, prob[1].to_f #Converts numnbers to floats
    return prob.inject(sym) #Adds/subtracts/multiplies/divides based on symbol
  end

  #If the program gets here, it did not match the reuired format
  puts "Invalid Tweet"
end

def tweet_result(result, user)
  #Tweets result to the supplied user
  msg = "@#{user}: #{result}"
  puts "Tweeted:  #{msg}"
  puts "Time:     #{Time.now}"
  Twitter.update(msg)
end

def record_tweet(user,text)
  puts "Recording to File: #{user}:#{text}"
  tweet_file = File.open('tweets.txt',"a")
  tweet_file.write("#{user}:#{text}\n")
  tweet_file.close
end

while true
  #Searches for messages addressed to Tweeulate
  Twitter.search("to:Tweetulate", :count => 3, :result_type => "recent").results.map do |status|
    #Check if tweet has already been received
    already_tweeted = false

    #Set mode based on if the file exists or not
    mode = File.exists?('tweets.txt') ? "r+" : "w+"

    #Check to see if tweet has already been replied to
    File.open("tweets.txt", mode).each do |line|
      already_tweeted = true if ("#{status.from_user}:#{status.text}") == line[0..-2]
    end

    if !already_tweeted
      #finds the result
      result = find_result(status.text)

      #Tweets result if not nil
      tweet_result(result, status.from_user) if result

      #Add tweet to file of tweets already received
      record_tweet(status.from_user,status.text)
    end
  end
  sleep(30) #Pause to limit number of requests
end
