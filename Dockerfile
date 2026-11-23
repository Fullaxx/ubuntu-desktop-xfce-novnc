# ------------------------------------------------------------------------------
# noVNC's web client (with its index.html) and its start script (app/app.sh)
# from ghcr.io/fullaxx/novnc (https://github.com/Fullaxx/novnc, Dockerfile.resolute)
FROM ghcr.io/fullaxx/novnc:resolute AS novnc

# ------------------------------------------------------------------------------
# Base Image : ghcr.io/fullaxx/ubuntu-desktop-xfce:26.04 (https://github.com/Fullaxx/ubuntu-desktop-xfce)
#              Ubuntu 26.04 LTS (Resolute Raccoon), Xfce 4.20, TigerVNC 1.15
# Support    : Apr 2026 - May 2031
FROM ghcr.io/fullaxx/ubuntu-desktop-xfce:26.04
LABEL author="Brett Kuskie <fullaxx@gmail.com>"

# ------------------------------------------------------------------------------
# Install supervisor,websockify and clean up
# (noVNC's web client is copied from the novnc image below: Ubuntu's novnc package
# would also install nodejs, about 80 MB, which only its build tools use)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      supervisor \
      websockify && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# ------------------------------------------------------------------------------
# Install noVNC: the web client, and the novnc image's start script as /app/novnc.sh
COPY --from=novnc /usr/share/novnc/ /usr/share/novnc/
COPY --from=novnc /app/app.sh /app/novnc.sh

# ------------------------------------------------------------------------------
# Keep the VNC server on localhost, behind noVNC
# (TigerVNC's system-wide policy wins over the "-localhost no" in /app/tiger.sh;
# tigervncserver logs a warning that says so at every start)
RUN printf '\n# ubuntu-desktop-xfce-novnc: only noVNC is exposed, the VNC server stays on localhost\n$localhost = "yes";\n' \
      >> /etc/tigervnc/vncserver-config-mandatory

# ------------------------------------------------------------------------------
# Install scripts and configuration files
COPY conf/supervisord.conf /etc/supervisor/supervisord.conf
COPY app/shutdown.sh /app/

# ------------------------------------------------------------------------------
# Expose ports
EXPOSE 8080

# ------------------------------------------------------------------------------
# Define default command
# (supervisord runs the desktop and noVNC: conf/supervisord.conf)
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
