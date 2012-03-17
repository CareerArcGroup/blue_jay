
module BlueJay
	class Client

		def add_friend(friend_id, follow = false)
			post("/friendships/create.json", :user_id => friend_id, :follow => follow)
		end

		def add_friend_by_screen_name(screen_name, follow = false)
			post("/friendships/create.json", :screen_name => screen_name, :follow => follow)
		end

		def un_friend(friend_id)
			post("/friendships/destroy.json", :user_id => friend_id)
		end

		def un_friend_by_screen_name(screen_name)
			post("/friendships/destroy.json", :screen_name => screen_name)
		end

	end
end