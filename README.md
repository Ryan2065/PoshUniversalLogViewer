# PoshUniversalLogViewer

The Posh Universal Log Viewer is a PowerShell utility that makes use of [ConvertFrom-String][ConvertFromString] to create nice looking log files from logs that are otherwise unreadable in a text editor. [ConvertFrom-String][ConvertFromString] needs a template in a special format in order to work properly. You can read more about how [ConvertFrom-String works in this MSDN article][CFExamples].

There are two scripts to this tool. The first is the "Universal Log Viewer.ps1". This is the main script which will parse the log file. Simply tell it what log files you want to read, then copy in a template (you can open it from a text file if you want) and then click Update or Refresh to load the results. If done correctly, you will be given all your results in a datagrid that is sortable and easily exportable.

The other script is "ConvertFrom-String Template Builder.ps1" which does what it says it does. Paste in your original text at the top, then tell it how many examples you are giving and how many columns you want to generate. After that, fill out each example and column. So if you have 2 examples and 2 columns, you'll want to fill in the data for Example 1, Column 1 and 2, then Example 2, Column 1 and 2. After everything is filled out, hit Generate.

If these instructions seem confusing, that's because you probably don't know much about ConvertFrom-String. You'll want to read up a little on it, then the instructions will make more sense! I'll be writing an in-depth blog post on each script in the future!

Requirements:
   - PowerShell 5
   - Some knowledge of ConvertFrom-String (will make better instructions so that's not needed in the future)

Known Issues:
   - There is a memory problem when parsing large log files. This is probably due to how I'm reading the text files, but am not sure how to fix it right now. If you plan on reading 20-40MB worth of logs at once, this will eat up a few GB of memory. Hopefully will get a fix in the future!

[ConvertFromString]: <https://technet.microsoft.com/en-us/library/dn807178.aspx>
[CFExamples]: <https://blogs.msdn.microsoft.com/powershell/2014/10/31/convertfrom-string-example-based-text-parsing/>