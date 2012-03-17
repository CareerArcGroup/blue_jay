
module BlueJay
	class Client

		def tweet(message, options={})
			 post("/statuses/update.json", options.merge(:status => message))
		end

		def un_tweet(tweet_id)
			 post("/statuses/destroy/#{tweet_id}.json")
		end

	end
end