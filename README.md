# Vanthrok_Server
 Backend for the mmorpg game, Vanthrok I'm developing. It's consists of a gateway server that handles all connections with incoming traffic from players to keep a layer of security between the player and personal information. If a player tries to log in, they will connect to the gateway which will talk to the authentication server. 
 
The authentication server will then validate usernames and passwords that are stored and sent in a hashed format for another layer of security and if the info is correct, it will send and authentication token to the player through the gateway and one to the game server. When they both receive the token the player then connects to the game server.

From there, the player can access their characters and equipment they've collected while playing under their account they created. They can interact with other players on the server and fight enemies together. Everything has server side authority to prevent players from cheating.
