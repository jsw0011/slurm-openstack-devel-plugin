#/usr/bin/bash

# Author: Jan Swiatkowski
# Company: IT4I

p_error() {
    echo "[ERROR] exit-error $1"
    exit $1
}

LOG="slurm_install_script_stdout.log"
#LOGERR="slurm_install_script_stderr.txt"
echo "Logging into $LOG"
if [ -z SLURM_VERSION ]; then 
    SLURM_VERSION="21.08.2"
fi

SLURM_GIT_REPO="https://github.com/SchedMD/slurm.git"
_STEPS=9

OPTIND=0
while getopts hm arg "$@"
do
    case $arg in "m") 
    #_STEPS=`expr 1 + $_STEPS`;
    _IS_MASTER=1 ;; ## if master, set variable, otherwise keep unset
    "h") echo "[HELP]";echo "   -m sets install mode for master server"; exit 0;;
    esac;
done;

echo "INSTALL DEPENDENCIES [1/$_STEPS]"

sudo -E yum config-manager --set-enabled powertools >> $LOG 2>&1 &&
sudo -E yum install -y git openssl openssl-libs pkgconf munge rng-tools munge-devel perl python3 gcc >> $LOG 2>&1

if [ $? -ne 0 ]; then p_error 1; fi;

# munge
#Install munge from the package manager, and then build slurm --with-munge= option, auth_munge.so should appear under $PREFIX/lib/slurm
echo "SET MUNGE KEY [2/$_STEPS]"

# generate munge key
if [ -n _IS_MASTER ]; then
rngd -r /dev/urandom >> $LOG 2>&1 &&
sudo -E /usr/sbin/create-munge-key -r >> $LOG 2>&1 &&
if [ $? -ne 0 ]; then p_error 2; fi;
else
sudo -E cp munge.key /etc/munge/
if [ $? -ne 0 ]; then p_error 2; fi;
fi;

sudo -E chown -R munge: /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge/ &&
sudo -E chmod 0700 /etc/munge/ /var/log/munge/ /var/lib/munge/ &&
sudo -E chmod 0755 /run/munge/ &&
sudo -E chown munge /etc/munge/munge.key >> $LOG 2>&1 &&
sudo -E chmod 400 /etc/munge/munge.key >> $LOG 2>&1
if [ $? -ne 0 ]; then p_error 2; fi;

sudo -E systemctl stop munge >> $LOG 2>&1 &&
sudo -E systemctl enable munge >> $LOG 2>&1 &&
sudo -E systemctl start munge >> $LOG 2>&1

if [ $? -ne 0 ]; then p_error 2; fi;

echo "BEGIN SLURM INSTALLATION [3/$_STEPS]"

#slurm
sudo -E yum install openssl openssl-devel pam-devel numactl numactl-devel hwloc lua readline-devel ncurses-devel libibmad libibumad make firewalld -y >> $LOG 2>&1
if [ $? -ne 0 ]; then p_error 3; fi;
sudo -E systemctl enable firewalld >> $LOG 2>&1 &&
sudo -E systemctl start firewalld >> $LOG 2>&1

if [ $? -ne 0 ]; then p_error 3; fi;

#curl -o ./slurm-$SLURM_VERSION.tar.bz2 https://download.schedmd.com/slurm/slurm-$SLURM_VERSION.tar.bz2 # doesnt work for centOS Stream 8

__REPO_PATH=$(echo $SLURM_GIT_REPO | sed -r 's/(.*\/)([A-Za-z0-9\_\-]+).git/ \2 /')

if [ ! -d $__REPO_PATH ]; then
git clone "$SLURM_GIT_REPO" >> $LOG 2>&1
fi

cd $__REPO_PATH
if [ $? -ne 0 ]; then p_error 3; fi;

git checkout "$SLURM_VERSION" >> $LOG 2>&1
echo "BUILD SLURM [4/$_STEPS]"

if [ -n _IS_MASTER ]; then
sudo -E hostname slurmMaster # !! ATTENTION name of the controller, should be dynamically generated
fi

./configure --with-munge >> $LOG 2>&1 &&
make >> $LOG 2>&1 && make check >> $LOG 2>&1 && sudo -E make install >> $LOG 2>&1
if [ $? -ne 0 ]; then p_error 4; fi;
echo "COPY CONFIGURATION [5/$_STEPS]"

if [ ! -d /etc/slurm ]; then sudo -E mkdir /etc/slurm >> $LOG 2>&1; fi
sudo -E cp ../slurm.conf /etc/slurm/ >> $LOG 2>&1
if [ $? -ne 0 ]; then p_error 5; fi;
sudo -E adduser slurm # add slurm user
if [ $? -ne 0 ]; then p_error 5; fi;
if [ -n _IS_MASTER ]; then
    sudo -E mkdir /var/spool/slurmctld >> $LOG 2>&1 &&
    sudo -E chown slurm: /var/spool/slurmctld >> $LOG 2>&1 &&
    sudo -E chmod 755 /var/spool/slurmctld >> $LOG 2>&1 &&
    sudo -E touch /var/log/slurmctld.log >> $LOG 2>&1 &&
    sudo -E chown slurm: /var/log/slurmctld.log >> $LOG 2>&1 &&
    sudo -E touch /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log >> $LOG 2>&1 &&
    sudo -E chown slurm: /var/log/slurm_jobacct.log /var/log/slurm_jobcomp.log >> $LOG 2>&1
    if [ $? -ne 0 ]; then p_error 5; fi;
fi;

sudo -E mkdir /var/spool/slurmd >> $LOG 2>&1 &&
sudo -E chown slurm: /var/spool/slurmd >> $LOG 2>&1 &&
sudo -E chmod 755 /var/spool/slurmd >> $LOG 2>&1 &&
sudo -E touch /var/log/slurmd.log >> $LOG 2>&1 &&
sudo -E chown slurm: /var/log/slurmd.log >> $LOG 2>&1

if [ $? -ne 0 ]; then p_error 5; fi;

#rpmbuild -ta slurm-$SLURM_VERSION.tar.bz2 # doesnt work for Stream 8
 
# echo "SYNC TIME PORTS [6/$_STEPS]"

# chkconfig ntpd on >> $LOG 2>&1
# ntpdate pool.ntp.org >> $LOG 2>&1
# systemctl start ntpd >> $LOG 2>&1

if [ -n _IS_MASTER ]; then
    echo "OPEN SERVER FIREWALL PORTS [6/$_STEPS]"
    sudo -E firewall-cmd --permanent --zone=public --add-port=6817/udp >> $LOG 2>&1  &&
    sudo -E firewall-cmd --permanent --zone=public --add-port=6817/tcp >> $LOG 2>&1 &&
    sudo -E firewall-cmd --permanent --zone=public --add-port=6818/tcp >> $LOG 2>&1 &&
    sudo -E firewall-cmd --permanent --zone=public --add-port=6818/udp >> $LOG 2>&1 &&
    sudo -E firewall-cmd --permanent --zone=public --add-port=7321/tcp >> $LOG 2>&1 &&
    sudo -E firewall-cmd --permanent --zone=public --add-port=7321/udp >> $LOG 2>&1 &&
    sudo -E firewall-cmd --reload
    if [ $? -ne 0 ]; then p_error 6; fi;
else
    echo "DISABLE FIREWALL [6/$_STEPS]"
# disabling firewall on slaves ??!!!
    sudo -E systemctl stop firewalld >> $LOG 2>&1 &&
    sudo -E systemctl disable firewalld >> $LOG 2>&1
    if [ $? -ne 0 ]; then p_error 6; fi;
fi

echo "CREATE SYSTEM V SERVICES [7/$_STEPS]"
if [ -n _IS_MASTER ]; then
    slurmctldSH='#!/usr/bin/sh
    SLURM="/usr/local/sbin/slurmctld"
    $SLURM -Df "/etc/slurm/slurm.conf"'
    echo "$slurmctldSH" | sudo -E tee /usr/bin/slurmctld.sh && sudo -E restorecon /usr/bin/slurmctld.sh >> $LOG 2>&1 && sudo -E chmod +x /usr/bin/slurmctld.sh >> $LOG 2>&1;
    if [ $? -ne 0 ]; then p_error 7; fi;
    # restorecon - reset security selinux context
    slurmctldService='[Unit]
Description = SLURM main controller service
Wants = munge.service

[Service]
ExecStart = /usr/bin/slurmctld.sh

[Install]
WantedBy = multi-user.target'
echo "$slurmctldService" | sudo -E tee /etc/systemd/system/slurmctld.service 
if [ $? -ne 0 ]; then p_error 7; fi;

fi

slurmdSH='#!/usr/bin/sh
    SLURM="/usr/local/sbin/slurmctld"
    $SLURM -Df "/etc/slurm/slurm.conf"'
echo "$slurmdSH" | sudo -E tee /usr/bin/slurmd.sh && sudo -E restorecon /usr/bin/slurmd.sh >> $LOG 2>&1 && sudo -E chmod +x /usr/bin/slurmd.sh >> $LOG 2>&1;
if [ $? -ne 0 ]; then p_error 7; fi;

# restorecon - reset security selinux context
    slurmdService='[Unit]
Description = SLURM node controller service
Wants = munge.service

[Service]
ExecStart = /usr/bin/slurmd.sh

[Install]
WantedBy = multi-user.target'
echo "$slurmdService" | sudo -E tee /etc/systemd/system/slurmd.service 

if [ $? -ne 0 ]; then p_error 7; fi;

echo "STARTING THE SLURM SERVICE [8/$_STEPS]"
if [ -n _IS_MASTER ]; then
sudo -E systemctl enable slurmctld.service >> $LOG 2>&1  &&
sudo -E systemctl start slurmctld.service >> $LOG 2>&1 &&
sudo -E systemctl status slurmctld.service >> $LOG 2>&1
if [ $? -ne 0 ]; then p_error 8; fi;
fi
sudo -E systemctl enable slurmd.service >> $LOG 2>&1 &&
sudo -E systemctl start slurmd.service >> $LOG 2>&1 &&
sudo -E systemctl status slurmd.service >> $LOG 2>&1
if [ $? -ne 0 ]; then p_error 8; fi;

echo "INSTALLATION DONE [$_STEPS/$_STEPS]"


exit 0