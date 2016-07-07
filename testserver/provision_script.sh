export DEBIAN_FRONTEND=noninteractive
MARKER_FILE="/usr/local/etc/vagrant_provision_marker"
# Only provision once
if [ -f "${MARKER_FILE}" ]; then
  exit 0
fi
# Update apt
apt-get update

# Add the vagrant user to the RVM group
#usermod -a -G rvm vagrant

# Install dependencies, Git, and stuff
# build-essential, rng tools
for package in git-core python-pip krb5-admin-server krb5-user libkrb5-dev; do
  apt-get install -y $package
done
yes | pip install robotframework

# Get our repos
#su -l -c 'cd ~/;git clone https://gerrit.openafs.org/openafs' vagrant
su -l -c 'cd ~/;git clone https://github.com/openafs-contrib/openafs-robotest' vagrant
su -l -c 'cd ~/openafs-robotest;./install.sh' vagrant
# System config for robotest
cd /usr/bin
wget http://download.sinenomine.net/user/jgorse/debian8x64/aklog-1.6.18
chmod +x aklog-1.6.18

# Prepend hosts with our more outside ip address because
#  loopback does not work for robotest
cd ~/
grep -v `hostname` /etc/hosts > tmp
rm /etc/hosts
echo `hostname -I` `hostname`.local `hostname` | cat - tmp > /etc/hosts
rm tmp

# Automatically move into the shared folder, but only add the command
# if it's not already there.
grep -q 'cd /vagrant' /home/vagrant/.bash_profile || echo 'cd /vagrant' >> /home/vagrant/.bash_profile

su -l -c 'ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa' vagrant
su -l -c 'cd /vagrant;ln -s ~/openafs-robotest' vagrant
su -l -c 'cp /vagrant/afs-robotest.conf ~/openafs-robotest/' vagrant

# Robotest finishing touches
#  TODO: move these to deploy/push method from dev box
#  TODO: deal with amd64_linux26-`date +%Y%m%d-%H%M%S`-`git log -n1 --format="%h"`.tar.gz filenames
su -l -c 'mkdir -p ~/amd64_linux26;tar zxf amd64_linux26-20160707-153401-8b57f9f.tar.gz -C ~/amd64_linux26 --strip-components=1' vagrant
su -l -c 'cd ~/openafs-robotest;./afs-robotest setup' vagrant
echo "do this to see it go: vagrant ssh"
echo "cd afs-robotest;./afs-robotest run"

# Touch the marker file so we don't do this again
touch ${MARKER_FILE}
