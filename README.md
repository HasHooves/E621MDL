# E621MDL
E621 Downloader

This program is a windows only software using powershell and batch files to quickly mass download files from E621.net. 
Config files can be duplicated and then customized so different batches can be ran without the need to type in preferences each time that the script is ran. 

.HOWTO

Running the "Run_me.bat" will start the program and provide you with a list of filters to choose. 

Edit or duplicate the Default.config.txt file to make oyur own filters! (text files with "Config" in the name are valid)

Here is an example of a modified config file:

VerbosePreference=false
Filters=Zebra
Blacklist=mlp,pony,My_little_pony
Score=0
Rating=safe,questionable,explicit
PageLimit=1
PostLimit=45

Tge above example would find all posts with the tag Zebra Except anything related to My Little Pony, including any item that has a score of 0 or above and then will scan one page of E621.net and then download the first 45 images found. 

VebosePreference is a true or false if you want verbose text
Filters are the tags you are looking for
Blacklist will avoid tags you choose
Score will search for anything greater than or equal to the number provided
Rating will search against the raiting of the image.
Page limit will determine how many pages are scanned looking for your images. 
Post limit will determine how many maximum posts should be considered. 

Be aware that there should NOT be spaces in your tags, use underscores to search for multiword tags and commas to seperate the tags. 
You can only use up to 7 search tags (Filters) before e621.net will reject the search. Blacklist tags have been added to allow you all 7 search tags, however you can use a negative sign (-) on a tag (like -MLP) to have E621.net filter out those results, this will give you the fastest results but will use one of your 7 filters. 

Look over the Cheatsheet on the E621.net site to get a better idea for advanced tag searching/formatting

https://e621.net/help/show/cheatsheet


In each downloads folder generated there will also be a log file identifying the files downloaded, this log file should not be deleted (It filters to ensure that the same post on e621.net is not downloaded a second time). 


.TODO

find modules or methods to add image tags to downloaded images
add downloaded URL into image metadata?

cycle through posts and pages until reaching the post limit
    unless we hit page limit first
    take into account filtering posts too!

set timers for retries?
add page limits
limit tag numbers


Logo credit: http://patorjk.com/software/taag/#p=display&f=Small%20Slant&t=e621%0ADownloader
