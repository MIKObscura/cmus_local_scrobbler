# Introduction
This is just a project I made for fun and to learn Ruby, it may not work properly on your end but you can submit issues to fix if you want to use it anyway for whatever reason.
I know lastfm exists and can be used with cmus but I wanted to do this for fun and do whatever I want with the data collected.

**Note: this program can only run if an instance of cmus is running!**

# How does it work?
Every 10 seconds it checks the cmus status with cmus-remote and parses it.  
The data of the current session is written in scrobbler_data.json, the data contained in this file is wiped out every session.   
All the tracks that were ever played as well as the amount of times they were played are stored in cache.json  
The program automatically stops when there is no instance of cmus running.

# What does each file do?
* main.rb: parses the cmus status and sends it to the other scripts
* scrobble_json.rb: uses the parsed status and writes it in the json files
* scrobble_stats.rb: makes various statistics from the cache.json and dates.txt files and dumps them in a file called stats.json (not fully implemented yet)
* track.rb: definition of the Track class, used by scrobble_stats.rb to make updating and computing stats easier 

Note: I didn't include a script or something else that uses the data stored in stats.json because the point of this program is to generate the data and updating it while letting you toy around with it however you like.

# How to run?
One thing you should do before you run is set the directory where the different json/txt files are saved, you can do this by changing the $home\_directory global in scrobble_stats.rb. You can optionally leave it as is, in which case it will be saved in the current directory.  
Then, once that's done, simply execute this command
> ruby path/to/file/main.rb

# Known issues
* [ ] Some data being in both cache.json and stats.json may be redundant and could use some rework to avoid that  
* [ ] Currently, repeating is not counted unless another track is played and registered beforehand
* [ ] Not tested yet but probably doesn't work with cmus' status_display_program

# Possible Improvements
* [ ] Adding a config file to customize various things like directory for json files, minimum time to register, stats to track,...
