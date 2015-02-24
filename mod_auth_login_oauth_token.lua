local new_sasl = require "util.sasl".new;
local json = require "util.json";
local http = require "net.http";
local base64 = require "util.encodings".base64.encode;
local waiter =require "util.async".waiter;

local usermanager = require "core.usermanager";
local accounts = module:open_store("accounts");

local provider = {};
local user_info = {};
local username;
local scopes;
local uname;
local path = "/home/ankit/Downloads/prosody-0.10/data/localhost/accounts/database";


function provider.test_password(username, token)
  log("debug", "test token");

        local wait, done = waiter();

        local code = -1;
        
        log("debug", "access token %s", token)
        
        -- for making a http request to the userinfo endpoint with token encoded
        
        http.request("https://api.learning-layers.eu/o/oauth2/userinfo?access_token=" .. http.urlencode(token), nil,
        
        function(body, _code)
             
             user_info = body;
             
             -- util.json for decoding json data.
             lua_value = json.decode(user_info);
             
             --parsing each and every value of table which has json data
             --for key, value in pairs(lua_value) do print(key, value) end
             
             --username contains valid prosody username with JID
             username = lua_value["preferred_username"] .. "@localhost";
             
             uname = lua_value["preferred_username"];
             
             if not provider.user_exists(uname) then
               provider.create_user(uname);
             end            
             
             code = _code;
             done();
        end);
        
        wait();

        if code >= 200 and code <= 299 then
                provider.introspect(token);
                return true;
        else
                module:log("debug", "HTTP auth provider returned status code %d", code);
                return nil, "Auth failed. Invalid token.";
        end

end        

function provider.introspect(token)

  http.request("https://api.learning-layers.eu/o/oauth2/introspect?token=" .. http.urlencode(token), { headers = { ["Accept"] = "application/json", ["Authorization"] = "Basic ODQ5YTkyNDgtNGUzOC00ZmFkLTgxYjktNmQ1MGFhZTkxNGM2OlhtYVFQR2pYSno4SU9hV1QwQW1tanRmTDVEaTNJMlpPTjk1MEFEVEs5X3pHVjZYWS1YaWJKd3o4ZjdPaVFhLUQya25uc2xxM0NGQmRXMGItVnBPa2pR", ["Content-Type"] = "application/x-www-form-urlencoded"} },
        
        function(body, _code)
             
             user_data = body;
              -- util.json for decoding json data.
             temp = json.decode(user_data);

             scopes = temp["scope"];

             if(file_exists(uname)) then
                os.remove("/home/ankit/Downloads/prosody-0.10/".. uname);
             end

             file = io.open("/home/ankit/Downloads/prosody-0.10/".. uname,"a");
    
             io.output(file);

             for token in string.gmatch(scopes, "[^%s]+") do
                io.write(token);
                io.write("\n");
             end    
             --io.write("\n");
    
             io.close(file);
             
        end);
end

function provider.get_password(username)
  return nil, "Not supported"
end

function file_exists(name)
   local file_found=io.open("/home/ankit/Downloads/prosody-0.10/".. uname,"r")
   if file_found==nil then
      file_found=false;
   else
      file_found=true;
  end
  return file_found
end

function provider.set_password(username, password)
  return nil, "Not supported"
end

function provider.user_exists(username)
      log("debug", "user_exists");
      local account = accounts:get(username);
      for line in io.lines(path) do 
        if line ~= username then
          log("debug", "account not found for username '%s'", username);
          return nil, "Auth failed. Invalid username";
        else 
        return true;
        end
      end
      --if not account then
      --   log("debug", "account not found for username '%s'", username);
      --   return nil, "Auth failed. Invalid username";
      --end
      --return true;
end

function provider.create_user(username)
    log("debug", "create_user");
    
    file = io.open(path,"a");
    
    io.output(file);
    
    io.write(username);
    
    io.write("\n");
    
    io.close(file);
   
   return true;
   -- return accounts:set(username);
  -- return nil, "Not supported"
end

function provider.delete_user(username)
  return nil, "Not supported"
end

function provider.get_sasl_handler()
  -- local getpass_authentication_profile = {
  --  plain_test = function(sasl, username, password, realm)
  --    local postdata = json_encode({ username = username, password = password });
  --    local result = http.request(post_url, postdata);
 --     return result == "true", true;
 --   end,
 -- };
  return new_sasl(module.host, {
                        plain_test = function(sasl, username, token, realm)
                                return provider.test_password(username, token), true;
                        end
                });
end


module:provides("auth", provider);
