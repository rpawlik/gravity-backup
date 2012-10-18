#!/bin/bash
#
#

#Tunable options##############################################

#Name of the VM running Chef-Server
chefvm="chef-server"

#Internal IP for the Chef Server VM
chefip="169.254.123.2"

#Location of VM's disk
vmdiskloc="/opt/rpcs/chef-server.qcow2"

#Backup directory to dump backed up files
backupdir="/backups/"

#Number of minute before removing old backup files and rerunning the backup
# 1 day = 1440
# 1 week = 10080
# 30 days = 43200
mins="30"

################################################################


if [ ! -d $backupdir ]
then
  echo "$backupdir does not exist, creating."
  mkdir $backupdir
fi
filetyme=""
filetyme=$(find /backups/ -name '*qcow2.gz' -mmin +$mins)
buexist=""
buexist=$(find /backups/ -name '*qcow2.gz')
if [ "$buexist" = "$filetyme" ] 
then
  if ps auwx | grep $chefvm | grep -v grep | awk {'print $21'} | grep $chefvm >/dev/null
  then
    while ps auwx | grep $chefvm | grep -v grep | awk {'print $21'} | grep $chefvm >/dev/null
    do
      echo "Shutting down $chefvm VM"
      ssh rack@$chefip 'sudo shutdown -h now'
      sleep 10
    done
    if [ -f $vmdiskloc ]
    then
      echo "Copying Chef VM and compressing the image. This may take some time."
      cat $vmdiskloc | gzip > $backupdir$chefvm-backup.qcow2.gz
      echo "Starting $chefvm"
      virsh start $chefvm >/dev/null
      echo -e "$chefvm backup complete! Find it here: \n$backupdir$chefvm-backup.qcow2.gz"
    else
      echo "$vmdiskloc does not exist!"
      exit 1
    fi
  else
    echo "Chef server VM not running, doing nothing."
  fi
else
   echo "$chefvm backup newer than $mins minutes, skipping."
fi


