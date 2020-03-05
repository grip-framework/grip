module Grip
  module Pipe
    class Basic
      class Credentials
        def initialize(@entries : Hash(String, String) = Hash(String, String).new)
        end
    
        def authorize?(username : String, given_password : String) : String?
          test_password = find_password(username, given_password)
          if Crypto::Subtle.constant_time_compare(test_password, given_password)
            username
          else
            nil
          end
        end
    
        private def find_password(username, given_password)
          # return a password that cannot possibly be correct if the username is wrong
          pw = "not #{given_password}"
    
          # iterate through each possibility to not leak info about valid usernames
          @entries.each do |(user, password)|
            if Crypto::Subtle.constant_time_compare(user, username)
              pw = password
            end
          end
    
          pw
        end
      end
    end
  end
end