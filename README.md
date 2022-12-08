# Introduction
This is just a project I made for fun and to learn Ruby.
I know lastfm exists and can be used with cmus but I wanted to do this for fun and do whatever I want with the data collected.

**Note: this program can only run if an instance of cmus is running!**

# How does it work?
Every 10 seconds it checks the cmus status with cmus-remote and parses it.  
The data of the current session is written in scrobbler_data.json, the data contained in this file is wiped out every session.   
All the tracks that were ever played as well as the amount of time they were played are stored in cache.json

# What does each file do?
* main.rb: parses the cmus status and sends it to the other scripts
* scrobble_json.rb: uses the parsed status and writes it in the json files
* scrobble_stats.rb: makes various statistics from the cache.json and dates.txt files and dumps them in a file called stats.json (not fully implemented yet)
* track.rb: definition of the Track class, used by scrobble_stats.rb to make updating and computing stats easier

# How to run?
One thing you should do before you run is set the directory where the different json/txt files are saved, you can do this by changing the $home\_directory global in scrobble_stats.rb. You can optionally leave it as is, in which case it will be saved in the current directory.  
Then, once that's done, simply execute this command
> ruby path/to/file/main.rb
