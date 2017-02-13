#!/bin/bash
# first, install ubuntu 16.04 - Install third-party software / Erase disk and install ubuntu  
# next, install guest additions. 
# then, touch ~/ubuntu_setup.ss && chmod 751 ~/ubuntu_setup.ss && vi ~/ubuntu_setup.ss
# usage: ./ubuntu_setup.ss

# disable auto update and upgrade
sudo systemctl disable apt-daily.service # disable run when system boot
sudo systemctl disable apt-daily.timer   # disable timer run

HTTP_PROXY_HOST='proxy.autozone.com'
HTTP_PROXY_PORT='8080'
HTTPS_PROXY_HOST='proxy.autozone.com'
HTTPS_PROXY_PORT='8080'
GITHUB_USERNAME='ryangraves37'
GITHUB_EMAIL='ryangraves37+github@gmail.com'
INTELLIJ_URL='https://download.jetbrains.com/idea/ideaIU-2016.3.4-no-jdk.tar.gz'
ECLIPSE_URL='http://download.springsource.com/release/ECLIPSE/neon/2/eclipse-java-neon-2-linux-gtk-x86_64.tar.gz'

get_tar() 
{
URL="$1"
cd ~/Downloads && \
curl -x https://"$PROXY_USERNAME":"$PROXY_PASS"@"$HTTPS_PROXY_HOST":"$HTTPS_PROXY_PORT" -fLO "$URL"
#if $? ; then
#  cd -
#else
#  echo "curl command failed for URL=$URL"
#  exit 1
#fi
}

echo "What is your proxy username?"
read PROXY_USERNAME
echo "What is your proxy password?"
read PROXY_PASS

export "http_proxy=\"http://$PROXY_USERNAME:$PROXY_PASS@$HTTP_PROXY_HOST:$HTTP_PROXY_PORT\""
export "https_proxy=\"https://$PROXY_USERNAME:$PROXY_PASS@$HTTPS_PROXY_HOST:$HTTPS_PROXY_PORT\""
export "HTTP_PROXY=\"http://$PROXY_USERNAME:$PROXY_PASS@$HTTP_PROXY_HOST:$HTTP_PROXY_PORT\""
export "HTTPS_PROXY=\"https://$PROXY_USERNAME:$PROXY_PASS@$HTTPS_PROXY_HOST:$HTTPS_PROXY_PORT\""

sudo dbus-launch gsettings set org.gnome.system.proxy mode 'manual' && \
  sudo dbus-launch gsettings set org.gnome.system.proxy.http host "$HTTP_PROXY_HOST" && \
  sudo dbus-launch gsettings set org.gnome.system.proxy.http port "$HTTP_PROXY_PORT" && \
  sudo dbus-launch gsettings set org.gnome.system.proxy.http authentication-user true && \
  sudo dbus-launch gsettings set org.gnome.system.proxy.http authentication-user "$PROXY_USERNAME" && \
  sudo dbus-launch gsettings set org.gnome.system.proxy.http authentication-password "$PROXY_PASS"
sudo dbus-launch gsettings set org.gnome.system.proxy.https host "$HTTPS_PROXY_HOST" && \
  sudo dbus-launch gsettings set org.gnome.system.proxy.https port "$HTTPS_PROXY_PORT"

sudo touch /etc/apt/apt.conf && \
  echo "Acquire::http::proxy \"http://$PROXY_USERNAME:$PROXY_PASS@$HTTP_PROXY_HOST:$HTTP_PROXY_PORT\";" | \
    sudo tee -a /etc/apt/apt.conf && \
  echo "Acquire::https::proxy \"https://$PROXY_USERNAME:$PROXY_PASS@$HTTPS_PROXY_HOST:$HTTPS_PROXY_PORT\";" | \
    sudo tee -a /etc/apt/apt.conf

echo "http_proxy=\"http://$PROXY_USERNAME:$PROXY_PASS@$HTTP_PROXY_HOST:$HTTP_PROXY_PORT\"" | \
  sudo tee -a /etc/environment
echo "https_proxy=\"https://$PROXY_USERNAME:$PROXY_PASS@$HTTPS_PROXY_HOST:$HTTPS_PROXY_PORT\"" | \
  sudo tee -a /etc/environment
# "You must duplicate in both upper-case and lower-case because (unfortunately) some programs looks for one or the other" - askubuntu
echo "HTTP_PROXY=\"http://$PROXY_USERNAME:$PROXY_PASS@$HTTP_PROXY_HOST:$HTTP_PROXY_PORT\"" | \
  sudo tee -a /etc/environment
echo "HTTPS_PROXY=\"https://$PROXY_USERNAME:$PROXY_PASS@$HTTPS_PROXY_HOST:$HTTPS_PROXY_PORT\"" | \
  sudo tee -a /etc/environment
echo "JAVA_HOME=\"/usr/lib/jvm/default-java\"" | \
  sudo tee -a /etc/environment

echo "" >> ~/.bashrc
echo "set -o vi" >> ~/.bashrc
  
source /etc/environment
source ~/.bashrc

sudo touch ~/keep
echo "Defaults env_keep += t\"http_proxy https_proxy HTTP_PROXY HTTPS_PROXY JAVA_HOME\"" | \
  sudo tee -a ~/keep
sudo chmod 0440 ~/keep
sudo visudo -c -q -f ~/keep && \
  sudo mv ~/keep /etc/sudoers.d/

sudo -E apt-get update && \
  sudo -E apt-get upgrade -y
  
# bread & butter
sudo -E apt-get install vim -y
sudo -E apt-get install tmux -y
sudo -E apt-get install git -y && \
  git config --global user.name "$GITHUB_USERNAME" && \
  git config --global user.email "$GITHUB_EMAIL"  
sudo -E apt-get install maven -y
sudo -E apt-get install subversion -y
sudo -E apt-get install gimp -y
sudo -E apt-get install vlc -y
sudo -E apt-get install aptitude -y
sudo -E apt-get install traceroute -y

# java - oracle
sudo -E add-apt-repository ppa:webupd8team/java -y && \
  sudo -E apt-get update && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections && \
  sudo -E apt-get install oracle-java8-installer -y
  
# tomcat
sudo apt-get install tomcat7 -y && \
sudo find /etc/default/tomcat7 -type f -exec sed -i 's/^JAVA_OPTS=*/JAVA_OPTS=-Djava.security.egd=file:\/dev\/.\/urandom -Djava.awt.headless=true -Xmx512m -XX:MaxPermSize=256m -XX:+UseConcMarkSweepGC/g' {} \;
sudo service tomcat7 restart
sudo -E apt-get install tomcat7-docs tomcat7-admin

# docker
sudo -E apt-get install apt-transport-https ca-certificates && \
  curl -x https://$PROXY_USERNAME:$PROXY_PASS@$HTTPS_PROXY_HOST:$HTTPS_PROXY_PORT -fL https://yum.dockerproject.org/gpg | \
    sudo apt-key add - && \
      sudo -E apt-get install software-properties-common && \
        sudo add-apt-repository "deb https://apt.dockerproject.org/repo/ ubuntu-$(lsb_release -cs) main" && \
  sudo -E apt-get update && \
  sudo -E apt-get install docker-engine -y && \
  sudo mkdir -p /etc/systemd/system/docker.service.d && \
  sudo touch /etc/systemd/system/docker.service.d/http-proxy.conf && \
  echo "[Service]" | \
  sudo tee -a /etc/systemd/system/docker.service.d/http-proxy.conf && \
  echo "Environment=\"HTTP_PROXY=$PROXY_USERNAME:$PROXY_PASS@$HTTP_PROXY_HOST:$HTTP_PROXY_PORT\"" | sudo tee -a /etc/systemd/system/docker.service.d/http-proxy.conf && \
  sudo systemctl daemon-reload && sudo systemctl restart docker

# chrome
sudo -E apt-get install libxss1 libappindicator1 libindicator7 -y && \
get_tar 'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb' && \
if sudo -E dpkg -i ~/Downloads/google-chrome*.deb ; then
  echo "Nothing to see here"
else
  sudo -E apt-get install -f -y && \
    sudo -E dpkg -i ~/Downloads/google-chrome*.deb
fi

# sublime 3
sudo -E add-apt-repository ppa:webupd8team/sublime-text-3 -y && \
  sudo -E apt-get update && \
    sudo -E apt-get install sublime-text-installer -y

# intellij
get_tar "$INTELLIJ_URL" && \
sudo tar -xf ~/Downloads/ideaIU*.gz -C /opt

# eclipse
get_tar "$ECLIPSE_URL" && \
sudo tar -xf ~/Downloads/eclipse*.gz -C /opt

# wireshark
sudo -E apt-add-repository universe -y && \
sudo -E apt-get update -y && \
sudo -E apt-get install wireshark -y && \
sudo adduser $USER wireshark

# remove bloatware
#echo "Do you wish to uninstall bloatware?"
#select yn in "Yes" "No"; do
#  case $yn in
#      Yes ) 
#	sudo aptitude remove '?depends(account-plugin-facebook)' -y \
#	sudo aptitude remove '?depends(account-plugin-flickr)' -y \
#	sudo aptitude remove '?depends(account-plugin-twitter)' -y \
#	sudo aptitude remove '?depends(account-plugin-windows-live)' -y \
#	sudo aptitude remove '?depends(gnome-mahjongg)' -y \
#	sudo aptitude remove '?depends(gnome-mines)' -y \
#	sudo aptitude remove '?depends(gnome-sudoku)' -y \
#	sudo aptitude remove '?depends(rhythmbox)' -y \
#	sudo aptitude remove '?depends(rhythmbox-plugins)' -y \
#	sudo aptitude remove '?depends(rhythmbox-plugin-zeitgeist)' -y \
#	sudo aptitude remove '?depends(unity-scope-yelp)' -y \
#	sudo aptitude remove '?depends(unity-webapps-common)' -y ; 
#        break ;;
#      No ) 
#	break ;;
#  esac
#done

sudo shutdown -r

exit 0
