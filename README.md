---
Tested: 2020-03-06
Version: v1.0.0
Status: Broken
---

# E621 Downloader

`E621MDL` is a image downloader tool to automatically download files from [e621.net](https://e621.net/).

- This program is a Windows only software using `PowerShell` and `Windows Batch` files to quickly mass download files from E621.net. Config files can be duplicated and customized so different batches can be ran without the need to type in preferences each time that the script is ran.
- Currently this version of the script is only useable in windows and has not been tested on a powershell version greater than 5.1

## How to run

- Running the `Run_me.bat` will start the program and provide you with a list of filters to choose.

## How to configure

- Edit or duplicate the Default.config.txt file to make your own filters!
  - > Note: Any text files with `Config` in the name are valid
- Here is an example of a modified config file:

```Config
VerbosePreference=false
Filters=Zebra
Blacklist=mlp,pony,My_little_pony
Score=0
Rating=safe,questionable,explicit
PageLimit=1
PostLimit=45
```

- The above example would process the following:
  - Find all posts with the `tag` Zebra
  - `Excluding` anything with "My Little Pony"
  - `Including` any item that has a score of `0 or above`
  - With `any` rating
  - Scan `1 page` of E621.net
  - Download the first `45 images found`

`VebosePreference` is a boolean true/false if you want verbose text. Filters are the tags you are looking for, Blacklist will avoid tags you choose, Score will search for anything greater than or equal to the number provided. Rating will search against the rating of the image. Page limit will determine how many pages are scanned looking for your images. Post limit will determine how many maximum posts should be considered.

- > Note: Be aware that there should NOT be spaces in your tags.
- Use underscores to search for multiword tags and commas to separate the tags. You can only use up to 7 search tags (Filters) before e621.net will reject the search.
- Blacklist tags have been added to allow you all 7 search tags, however you can use a negative sign `-` on a tag `like -MLP` to have E621.net filter out those results, this will give you the fastest results but will use one of your 7 filters.
- Look over the [Cheatsheet](https://e621.net/help/show/cheatsheet) on the E621.net site to get a better idea for advanced tag searching/formatting.

## Logging

- In each downloads folder generated there will also be a log file identifying the files downloaded.
  - > Note: This log file should not be deleted. it filters to ensure that the same post on e621.net is not downloaded a second time.

## References

- The logo in the script was created using [patorjk.com/software/taag](http://patorjk.com/software/taag/#p=display&f=Graffiti&t=Type%20Something%20)
