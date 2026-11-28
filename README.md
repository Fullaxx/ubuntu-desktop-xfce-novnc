# Ubuntu Desktop running Xfce4 in a web browser (noVNC)

[ubuntu-desktop-xfce](https://github.com/Fullaxx/ubuntu-desktop-xfce) and [noVNC](https://github.com/Fullaxx/novnc) in one image. \
The VNC server (TigerVNC) only listens on localhost inside the container: noVNC, on port 8080, is the way in.

## Base Docker Image
[ghcr.io/fullaxx/ubuntu-desktop-xfce](https://github.com/Fullaxx/ubuntu-desktop-xfce):26.04 (Ubuntu 26.04, Xfce 4.20, TigerVNC 1.15) \
noVNC's web client and start script come from [ghcr.io/fullaxx/novnc](https://github.com/Fullaxx/novnc):resolute

## Get the image or build it locally
```
docker pull ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc

docker build -t="ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc" https://github.com/Fullaxx/ubuntu-desktop-xfce-novnc.git
```
`:latest`, `:26.04` and `:resolute` are the same image. It is rebuilt at every push to `master`.

## Connect with a web browser
Run the image on localhost port 8080, then browse to http://127.0.0.1:8080/
```
docker run -d -p 127.0.0.1:8080:8080 ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
noVNC connects by itself and resizes the desktop to fit the browser window, unless `VNCRESIZE='0'` keeps its size ([Desktop Options](#desktop-options)).

## noVNC Options
Optional: Set Password Authentication (the browser asks for it) \
Default: No Authentication
```
-e VNCPASS='vncpass'
```
Optional: Set Read-Write and Read-Only password (the read-only password gives a view-only desktop) \
Default: No Authentication
```
-e VNCPASS='vncpass' -e VNCPASSRO='readonly'
```
Optional: Serve noVNC over HTTPS, with a certificate (key and certificate in one file) from the directory mounted on /cert \
Default: HTTP only \
A quick self-signed certificate: [CERTIFICATE_CREATION.md](https://github.com/Fullaxx/novnc/blob/master/CERTIFICATE_CREATION.md)
```
-e CERTFILE='novnc.pem' -v /tmp/cert:/cert
```

## Desktop Options
Everything in ubuntu-desktop-xfce's README works the same here: \
[VNC Options](https://github.com/Fullaxx/ubuntu-desktop-xfce#vnc-options) /
[Non-root users](https://github.com/Fullaxx/ubuntu-desktop-xfce#non-root-users) /
[TimeZone](https://github.com/Fullaxx/ubuntu-desktop-xfce#timezone-configuration) /
[Locale](https://github.com/Fullaxx/ubuntu-desktop-xfce#locale-configuration) /
[Input Method](https://github.com/Fullaxx/ubuntu-desktop-xfce#input-method-configuration) /
[Wallpaper](https://github.com/Fullaxx/ubuntu-desktop-xfce#wallpaper-configuration) /
[Extra privileges](https://github.com/Fullaxx/ubuntu-desktop-xfce/blob/master/PRIVILEGES.md) /
[Troubleshooting](https://github.com/Fullaxx/ubuntu-desktop-xfce/tree/master/troubleshooting)

Four of them work a little differently behind noVNC:
- `VNCRES` is only the size the desktop starts with: noVNC resizes it to the browser window, unless `VNCRESIZE='0'`.
- `VNCRESIZE='0'` keeps the desktop at `VNCRES`: TigerVNC refuses noVNC's resize requests, and noVNC shows the desktop at its own size, with scrollbars when the window is smaller. To have noVNC scale it to the window instead, browse to http://127.0.0.1:8080/vnc.html?autoconnect=1&resize=scale (http://127.0.0.1:8080/ asks for remote resizing at every visit, overriding a Scaling mode saved in noVNC's settings).
- `VNCPORT` moves the VNC server, which only listens on localhost, so it only matters with `--network=host`. noVNC follows it, and stays on port 8080.
- `INPUT_METHOD` installs fcitx5 at the container's first start, before the desktop starts, so the desktop comes up about half a minute after `docker run` instead of 3 seconds.
  noVNC's page loads right away, but says "Failed to connect to server" until then: click Connect once `docker logs` shows `Input method: pinyin (fcitx5; Ctrl+Space switches)` (with your input methods). \
  In a browser on a Mac, macOS takes Ctrl+Space for its own input sources: [INPUT_METHODS.md](https://github.com/Fullaxx/ubuntu-desktop-xfce/blob/master/INPUT_METHODS.md#mac-clients) has two ways around it.

## Security
Without `VNCPASS`, anyone who can reach port 8080 gets the desktop, and the desktop runs as root unless `VNCUSERMAP` is set. \
Publish the port on 127.0.0.1, as in these examples, or set `VNCPASS`, plus `CERTFILE` so the connection is encrypted.

## Run the image
Run the image on localhost port 8080 with default configuration
```
docker run -d -p 127.0.0.1:8080:8080 ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
Run the image with Password Authentication
```
docker run -d -p 127.0.0.1:8080:8080 -e VNCPASS='vncpass' ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
Run the image with Read-Write and Read-Only password (Using R/O pass requires R/W pass)
```
docker run -d -p 127.0.0.1:8080:8080 -e VNCPASS='vncpass' -e VNCPASSRO='readonly' ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
Run the image with a desktop that keeps its size; noVNC scales it to the browser window at http://127.0.0.1:8080/vnc.html?autoconnect=1&resize=scale
```
docker run -d -p 127.0.0.1:8080:8080 -e VNCRESIZE='0' ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
Run the image with HTTPS, using the certificate novnc.pem found in /tmp/cert, then browse to https://127.0.0.1:8080/
```
docker run -d -p 127.0.0.1:8080:8080 -e CERTFILE='novnc.pem' -v /tmp/cert:/cert ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
Run the image as a new non-root user account
```
docker run -d -p 127.0.0.1:8080:8080 -e VNCUSERMAP='guest/1001' ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
Run the image in Berlin, with German menus, dates and numbers
```
docker run -d -p 127.0.0.1:8080:8080 -e TZ='Europe/Berlin' -e LOCALE='de_DE' ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
Run the image with Chinese menus, typing Chinese with Pinyin (Ctrl+Space switches)
```
docker run -d -p 127.0.0.1:8080:8080 -e LOCALE='zh_CN' -e INPUT_METHOD='pinyin' ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
Run the image with more shared memory, for web browsers inside the desktop ([why](https://github.com/Fullaxx/ubuntu-desktop-xfce/blob/master/troubleshooting/WEB_BROWSERS.md))
```
docker run -d -p 127.0.0.1:8080:8080 --shm-size 2g ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
Run the image so that it comes back with a fresh desktop after you log out
```
docker run -d -p 127.0.0.1:8080:8080 --restart unless-stopped ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
Run the image using host networking: noVNC on port 8080 of every host address, so set a password \
(the VNC server binds to the host's 127.0.0.1:5909)
```
docker run -d --network=host -e VNCPORT='9' -e VNCPASS='vncpass' ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```

## How it works
supervisord ([conf/supervisord.conf](conf/supervisord.conf)) runs each project's own start script, unchanged:
- `desktop`: ubuntu-desktop-xfce's `/app/app.sh`. Its startup stages, then TigerVNC (`tiger.sh`) until the desktop session ends.
- `novnc`: novnc's `app.sh` (as `/app/novnc.sh`). websockify serves the web client on port 8080 and connects it to the VNC server on 127.0.0.1, port 5900 + `VNCPORT`.

The VNC server stays on localhost because of one line in `/etc/tigervnc/vncserver-config-mandatory` (`$localhost = "yes";`), which wins over the `-localhost no` in `tiger.sh`.
tigervncserver says so in `docker logs` at every start, and that's expected:
```
tigervncserver: Warning: /etc/tigervnc/vncserver-config-mandatory is overriding localhost from commandline to be "1"!
```
- **Logging out** of Xfce stops the container, as in ubuntu-desktop-xfce: [app/shutdown.sh](app/shutdown.sh) stops supervisord when the desktop ends. With `--restart unless-stopped`, Docker brings it back with a fresh desktop a few seconds later.
- **The exit code** is 0, even when the desktop can't start (such as `VNCUSERMAP='guest/1000'`): `docker logs` explains why.
- **If websockify stops**, supervisord restarts it, and the desktop keeps running. If it can't start at all (a `CERTFILE` that isn't in /cert), the container stops after a few tries.
- **`reaped unknown pid`** lines in `docker logs` are supervisord cleaning up processes the desktop left behind.
- **Port 5901** shows up in `docker inspect` because the base image declares it, but nothing outside the container can reach it.

Check the whole path on a Docker host (CI runs this before it publishes)
```
tests/novnc.sh ghcr.io/fullaxx/ubuntu-desktop-xfce-novnc
```
