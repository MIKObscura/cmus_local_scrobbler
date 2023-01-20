# Introduction
This is just a project I made for fun and to learn Ruby, it may not work properly on your end but you can submit issues to fix if you want to use it anyway for whatever reason.
I know lastfm exists and can be used with cmus but I wanted to do this for fun and do whatever I want with the data collected.

**Note: this program can only run if an instance of cmus is running!**

# How does it work?
Every 10 seconds it checks the cmus status with cmus-remote and parses it.  
The data of the current session is written in scrobbler_data.json, the data contained in this file is wiped out every session.   
All the tracks that were ever played as well as the amount of times they were played are stored in the db file.
The program automatically stops when there is no instance of cmus running.

# What does each file do?
* main.rb: parses the cmus status and sends it to the other scripts
* scrobble_json.rb: uses the parsed status and writes it in the json files
* scrobble_stats.rb: makes various statistics from the database and dates.txt files and dumps them in a file called stats.json (not fully implemented yet)
* database.rb: contains a single function to add a track to the database, increments its plays counter if it's already there
* config.rb: reads the configuration file

Note: I didn't include a script or something else that uses the data stored in stats.json because the point of this program is to generate the data and updating it while letting you toy around with it however you like.

# Configuration
First create a file called scrobbler_config.txt in whatever directory you execute the script from
The format is key=value with one on each line  
It will be expanded in the future but this is what it has for now:
* home_path: sets the directory where json files are saved and where the db is located, note that it needs to end with a /
* keep_previous_sessions: does not wipe the content of scrobble_data.json and instead creates a new one every session
* time_to_register: minimum time to register a track, if it's < 1 then it's treated as a percentage of the track (i.e. 0.5 will register the track once it's at half of its duration). If it's > 1 then it's treaded as a static amount of seconds 
* weekly/monthly/yearly_stats: enables weekly/monthly/yearly stats on top of overall stats  
Here's an example:
``` 
home_path=/home/user/cmus_scrobbler/
weekly_stats=true
monthly_stats=true
yearly_stats=true
keep_previous_sessions=true
time_to_register=0.5
```


# How to run?
Make a configuration file then simply execute this command
> ruby path/to/file/main.rb

# Known issues
* [ ] Currently, repeating is not counted unless another track is played and registered beforehand
* [ ] doesn't work with cmus' status_display_program [Note: the time to register can't be configured when using status_display_program so I won't implement that]
