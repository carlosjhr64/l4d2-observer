# L4d2Observer

* [VERSION 1.0.230505](https://github.com/carlosjhr64/l4d2-observer/releases)
* [github](https://www.github.com/carlosjhr64/l4d2-observer)

## DESCRIPTION

A L4D2 server observer that kicks players out for poor play.

## HELP
```console
$ l4d2-observer --help
### L4D2 Friendly Fire Observer ###
Usage:
  l4d2-observer [:options+] [<srcds_dir>]
Options:
  --ff=N      	FF limit
  --exposure=N	Exposure limit
  --pardons=N 	Pardons limit
  --pity=N    	Pity limit
  --kicks=N   	Kicks limit
  --admin=W   	Admin's name
Types:
  N   /^\d$/
  W   /^\w+$/
# Notes:
#   srcds_dir defaults to ~/Steam/L4D2-server
#   N defaults to 3
#   admin defaults to "Caprichozo" (me :D)
```
## FLOWCHART
```mermaid
flowchart TD
  A[/Server log message/]-->B{Client connected?}
  A-->C
  B-->D
  C-->D
```
## INSTALL

You'll need:

* Ruby 3.2 and the following gems:
  * help_parser
  * rainbow
* Runs on Linux
* Obviously a working L4D2 dedicated server:
  * See [Linode's guide](https://www.linode.com/docs/guides/left-4-dead-2-multiplayer-server-installation/)
```console
git clone git@github.com:carlosjhr64/l4d2-observer.git
cd l4d2-observer
./bin/compile > l4d2-observer
mv l4d2-observer /path-to/bin/l4d2-observer
# And just run it...
screen # preferably so that you can detach
l4d2-observer --admin=yourPlayerName
```
Please read the code for all the goodies!

## LICENSE

Copyright (c) 2023 CarlosJHR64

Permission is hereby granted, free of charge,
to any person obtaining a copy of this software and
associated documentation files (the "Software"),
to deal in the Software without restriction,
including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and
to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice
shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS",
WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH
THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
