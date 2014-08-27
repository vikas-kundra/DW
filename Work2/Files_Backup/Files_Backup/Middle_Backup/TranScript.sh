#!/bin/bash
. ./server.cfg


#################################Function For Retrial Logic##################################################################################################
ReTrial(){

val=1
while [[ $val -le 4 ]]; do
	#statements
	
	echo "Value for Retrial Attempts is $val"
rsync -a -i  -e ssh --bwlimit=20 --log-file=./Result2	  --timeout=5  $HOME_FOLDER/$1 $DEST_NAME@$DEST_IP:$DESTINATION_FOLDER

Last_Rec=$?
echo "Value for exit status is $Last_Rec"
if [[ Last_Rec -eq 0 ]]; then
	#statements
	echo "Transfer Is SuccessFul..After Retrial"
	return 0

elif [[ Last_Rec -eq 23 ]]; then
	#statements
	echo "Error in local Directory Path"
	return 1

elif [[ Last_Rec -eq 11 ]]; then
	echo "Error In Destination Directory Path"
	return 1
	#statements
elif [[ Last_Rec -eq 255 ]]; then
	#statements
	echo "Remote Connection Is not establishing.."
	sleep 10
#	break

fi
val=$(($val+1))
done

if [[ $val -eq 5 ]]; then
	#statements
	echo "Transfer Was Not Successful..Even After Retrial!!!"
    return 1
fi

}

######################################################Function For Transfering#########################################################
Transfer(){
#rsync -a -i  -e ssh --bwlimit=20 --log-file=./Result2	  --timeout=5  /home/ubuntu/temp/Work/Middle/$1  $vikas2@$192.168.0.213:~/temp/Work/Middle
rsync -a -i  -e ssh --bwlimit=20 --log-file=./Result2	  --timeout=5  $HOME_FOLDER/$1 $DEST_NAME@$DEST_IP:$DESTINATION_FOLDER
Last_Rec=$?
echo "Inside Transfer"
echo "Value for exit status is $Last_Rec"
if [[ Last_Rec -eq 0 ]]; then
	#statements
	y=$1
	echo  "Value for Y is " $y
	#mv "$1" "$1"
	echo "Transfer Is SuccessFul..Exiting This Loop"
	mv $y ~/temp/Work/LogsSuccess

	#statements
#elif [[ Last_Rec -eq 20 ]]; then
	#statements
#	echo "Abrupt Ending Of Script"
#	break

else 
	ReTrial $1
	m=$?


   echo "Value in Last Variab is $m"
   if [[ $m == 0 ]]; then
   
   	#statements
   mv $1 ~/temp/Work/LogsSuccess
   else
   mv $1 ~/temp/Work/LogFailed
   fi 
fi

}
TransFerMD(){
cd ~/temp/Work/Middle
m=$(ls -l|awk '{print $9}'|grep MD5)
echo "Inside TransferMD"
Transfer $m
}


####################################Function To Transfer Archieves######################################################################
TransferA(){
cd ~/temp/Work/Middle
p=$( ls -l|awk '{print $9}'|grep -v MD5|grep tar.gz)
echo "Inside TransferMD"
for x in $p
do
    Transfer $x
	done
}


TransFerMD
TransferA