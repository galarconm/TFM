#!/bin/bash
# Iniciar Spyder con soporte VNC
xvfb-run -s "-screen 0 1024x768x24" 
#xvfb-run -s "-screen 0 1920x1080x24" spyder
##funciona con el dockerfile spideyrpd

