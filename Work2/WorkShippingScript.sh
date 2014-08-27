#!/bin/bash
. ./ServerConfigurationFIle.cfg

##Evaluating File Name For the File Names
date_val=$(date +'%m_%d_%y')
echo "Date Value stored is $date_val"
file_name=$APP_NAME$date_val



###########################Function To Send Alert Emails##############################################################################
function ErrorEmail()
{
	cd $WORK_DIR
	error_message=$*
	touch AlertEmail
    cat AlertEmailTemplate|sed "s/<MESSAGE>/$error_message/g;s/<DATE>/$m2/g;s/<SENDER_SERVER>/$APP_NAME/g;s/<DEST_NAME>/$DEST_NAME/g;s/<DEST_IP>/$DEST_IP/g;">AlertEmail
}


##########################################Moving Files From Dblogs And Compressing Them##################################################################
function Compress(){

cd $WORK_DIR

touch ShippingLog
chmod 777 ShippingLog

cd $DBLOGS_DIR

db_logs_records=$(ls|wc -l)

##Checking If Files Are Present For Processing in DBLOGS Directory
if [[ db_logs_records -ne 0 ]]; then
	#statements

chmod 777 File*

cd $SHIPPEDLOG_DIR

##Creating gzip of all the files Present in DBLOG Directory
tar cvzf $file_name.tar.gz $DBLOGS_DIR
if [[ $? -eq 0 ]]; then
	#statements
	echo "All Files have been moved Successfully"|
	rm $DBLOGS_DIR/*


#echo "File Name is $file_name"
cd $SHIPPEDLOG_DIR
touch $file_name.tar.gz_MD5

##Creating MD5 For the gzip
md5sum $file_name.tar.gz>$file_name.tar.gz_MD5
#cat APP1-23-08-12.tar.gz_MD5 >~/temp/Work/ShippingLog
else
	error="Compress Operation was not Successful"
	ErrorEmail $error
	return 1
fi

fi

}
##########################################Splitting Files And Calculating MD5################################################################
function Split()
{

cd $SHIPPEDLOG_DIR
compressed_records_number=$(ls -l|awk '{print $9}'|grep -v MD5|grep .tar|wc -l)

##Checking For Gzip Files in ShippedLogs Directory
if [[ $compressed_records_number -ne 0 ]]; then
	#statements

compressed_records_value=$(ls -l|awk '{print $9}'|grep -v MD5|grep .tar)
	#statements
echo "Value of compressed Records is $compressed_records_value"

##Processing Every gzip file present in Folder
for compressed_record in $compressed_records_value
do
cd $MIDDLE_DIR
split -b$BYTE_VALUE $SHIPPEDLOG_DIR/$compressed_record  $compressed_record.
last_val=$?
if [[ $last_val -eq 0 ]]; then
	#statements
index=1
echo "Value in Comprssed Record is $compressed_record"
file_val="$compressed_record"

##Renaming Split Files
for file in $compressed_record.*
do
    
    mv "$file" "$file_val.$index"
 #   md5sum "$j.$i"
    index=`expr $index + 1` 
done

file_collection=$(ls -l|awk '{print $9}'|grep $compressed_record)
	

##Creating MD5 For all the Split Parts
for fil in $file_collection
do
#echo $x
touch "$fil"_MD5	
md5sum "$fil">"$fil"_MD5
done

cd $SHIPPEDLOG_DIR
rm $compressed_record

else
##Sending Alert Mail in case Split operation is not Performed Successfully
error_messag="Cannot Perform Split For $compressed_record"
AlertEmail $error_messag
fi
done

fi
}

###############################Function To Check For Archieve in Logs Failed###########################################################
function FailedCheck(){
	
    cd $LOG_FAILED_DIR
	records=$(ls|wc -l)
	if [[ $records != 0 ]]; then
		#statements
		echo "Inside Function To Transfer Files"
		mv $LOG_FAILED_DIR/* $MIDDLE_DIR||ErrorEmail "Unable To Move Files From LogFailed To Archieve Folder"
#		if [[ $? -ne 0 ]]; then
#			ErrorEmail "Unable To Move Files From LogFailed To Archieve Folder"
			#statements
#		fi
	fi
}
#################################Function For Retrial Logic##################################################################################################
function ReTrial(){

val=1

##Loop For the number of attempts for retrial
while [[ $val -le $NUMBER_OF_RETRIAL ]]; do
	#statements
	
	echo "Value for Retrial Attempts is $val"
rsync -a -i  -e ssh --bwlimit=$BAND_WIDTH_LIMIT --log-file=./Result2	  --timeout=$TIMEOUT  $HOME_FOLDER/$1 $DEST_NAME@$DEST_IP:$DESTINATION_FOLDER

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

if [[ $val -eq $NUMBER_OF_RETRIAL+1 ]]; then
	#statements
	echo "Transfer Was Not Successful..Even After Retrial!!!"
    return 1
fi

}

######################################################Function For Transfering#########################################################
function Transfer(){
#rsync -a -i  -e ssh --bwlimit=20 --log-file=./Result2	  --timeout=5  /home/ubuntu/temp/Work/Middle/$1  $vikas2@$192.168.0.213:~/temp/Work/Middle

####### Checking If File Has Already been Transferred#############
echo $1|grep Sent
pipe_v=${PIPESTATUS[1]}
if [[ $pipe_v -eq 0 ]]; then
	#statements
	echo "File is Already Present,Don't Need To Resend"
	mv $1 $LOG_SUCCESS_DIR
else

##Transferring File To Remote Server
rsync -a -i  -e ssh --bwlimit=$BAND_WIDTH_LIMIT --log-file=./Result2	  --timeout=$TIMEOUT  $HOME_FOLDER/$1 $DEST_NAME@$DEST_IP:$DESTINATION_FOLDER
Last_Rec=$?
echo "Inside Transfer"
echo "Value for exit status is $Last_Rec"
if [[ Last_Rec -eq 0 ]]; then
	#statements
	file_name_sent="$1_Sent"
	mv "$1" "$1_Sent"
	echo  "Value for Y is " $file_name_sent
	#mv "$1" "$1"
	echo "Transfer Is SuccessFul..Exiting This Loop"
	mv $file_name_sent $LOG_SUCCESS_DIR

	#statements
#elif [[ Last_Rec -eq 20 ]]; then
	#statements
#	echo "Abrupt Ending Of Script"
#	break

else 
   ReTrial $1
   last_command_value=$?
   echo "Value in Last Variab is $last_command_value"
   if [[ $last_command_value == 0 ]]; then
    #statements
   	mv $1 $LOG_SUCCESS_DIR
   
   else
    mv $1 $LOG_FAILED_DIR
   
   fi 
fi

fi

}

#######################################For Transferring MD5 Files#######################################################################
function TransFerMD(){

cd $MIDDLE_DIR
##Searching For all MD5 Files in Archieve Directory
md5_file_collection=$(ls -l|awk '{print $9}'|grep MD5)
#echo "Inside TransferMD"
for md5_file in $md5_file_collection
do
    Transfer $md5_file
done
}    



####################################Function To Transfer Archieves######################################################################
function TransferA(){

cd $MIDDLE_DIR
##Searching for all Files except MD5 in Archieve Directory
file_archieve_collection=$( ls -l|awk '{print $9}'|grep -v MD5|grep tar.gz)
#echo "Inside TransferMD"
for file_archieve in $file_archieve_collection
do
    Transfer $file_archieve
done
}

Email(){

cd $LOG_SUCCESS_DIR
file_success_collection=$(ls -l|awk '{print $9}'|grep Sent)
l=" "
for x in $file_success_collection
do
	k=$(echo $x|sed 's/_Sent//')
    l=$l" "$k
#  echo "Value in inner loop of l is $l"
done

#echo "Value in k is $l"
#cat EFile|sed "s/<FILES_SUCCESS>/$l/g"


################################################List Of Files Which  Have Failed In Transfer##################################################
cd $LOG_FAILED_DIR
file_failed_collection=$(ls -l|awk '{print $9}'|grep .tar.gz)
l1=" "
cd $LOG_SUCCESS_DIR
#echo "Value inner loop is $m" 
for x in $file_failed_collection
do
	k=$(echo $x|sed 's/_Sent//')
  l1=$l1" "$k
 # echo "Value in inner loop of l is $l"
done

#echo "Value in k is $l"
cd $WORK_DIR
m2=$(date)	
echo "Date is $m2"
touch Efile2
cat EFile|sed "s/<FILES_FAILED>/$l1/g;s/<FILES_SUCCESS>/$l/g;s/<DATE>/$m2/g;s/<SENDER_SERVER>/$APP_NAME/g;s/<DEST_NAME>/$DEST_NAME/g;s/<DEST_IP>/$DEST_IP/g;">Efile2


}



#Order Of Function Calls
#Compress
Split
#FailedCheck
#TransFerMD
#TransferA
#Email

	
function Main()
{
	cd $DBLOGS_DIR
#	records_db_logs=$(ls|wc -l)
#	if [[ $records_db_logs != 0 ]]; then
		#statements
		Compress
		Split
#	fi
	
	FailedCheck

 #   cd $MIDDLE_DIR
	records_archieve=$(ls|wc -l)
	if [[ $records_archieve != 0 ]]; then
		#statements
		TransFerMD
		TransferA
		Email
		
	fi

}

