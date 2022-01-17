# qdlaravel

A quick and dirty Laravel stack.

___"It works on my system"___  
Aye, not tested anywher other than a Linux system.  For the containers to build you'll need docker-compose, docker, and, er, I *think* that's all.

## What lives where

| *Directory* | *What* |
| -- | -- |
| storage/app | Laravel stuff, perms are tweaked by the container so you can edit them in your favour IDE |
| storage/database | MySQL.  If it's empty, a default MySQL system will be dropped into place first, otherwise, it's just mounted to the MySQL container |
| storage/certs | Cert files for nginx; if it's empty a self signed cert will be generated. |

Note that the `BIND-MARKER` files are required (so that the container can be sure bind mount is successful).

## Quick-start

Tweak `docker-compose.yaml` to set the URL of your choice:

> `WWWDOMAIN: www.qdlaravel.local`

... or, set `www.qdlaravel.local` to 127.0.0.1 in your systems hosts file.

Launch with `docker-compose up` (or include `-d` for daemon mode).  When it's up, hop onto the web container:

> `docker container exec -it qdlaravel-web /bin/bash`

.... and switch to the `/storage/app` dir:

> `cd /storage/app/``

Now create your laravel project:

> `laravel new ThisIsATestApp`

Like this...

```
root@03bf89467e2e:/storage/app# laravel new ThisIsATestApp

 _                               _
| |                             | |
| |     __ _ _ __ __ ___   _____| |
| |    / _` | '__/ _` \ \ / / _ \ |
| |___| (_| | | | (_| |\ V /  __/ |
|______\__,_|_|  \__,_| \_/ \___|_|

Creating a "laravel/laravel" project at "./ThisIsATestApp"
Installing laravel/laravel (v8.6.2)
  - Downloading laravel/laravel (v8.6.2)
```

Now, blow away the `public` symlink and recreate it to your new laravel instance public dir:

> `root@03bf89467e2e:/storage/app# rm public`  
> `root@03bf89467e2e:/storage/app# ln -s ThisIsATestApp/public public`

Now restart the containers and robert is your mothers brother.



##TODO

  * match local UID and have everything inside containers use that UID? (easier for permissions on files n'ting)