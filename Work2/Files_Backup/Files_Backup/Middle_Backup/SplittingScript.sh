cd ~/temp/Work/Middle
split -b100 ~/temp/Work/ShippedLogs/APP1-23-08-12.tar.gz  APP1-23-08-12.tar.gz.
i=1

j="APP1-23-08-12.tar.gz"
for file in APP1-23-08-12.tar.gz.*
do
    
    mv "$file" "$j.$i"
 #   md5sum "$j.$i"
    i=`expr $i + 1` 
done

y=$(ls -l|awk '{print $9}'|grep APP1)
#echo "Values in y is $y"
mkdir APP1-23-08-12.tar.gz_MD5

for x in $y
do
#echo $x
touch "$x"_MD5	
md5sum "$x">"$x"_MD5
mv "$x"_MD5 APP1-23-08-12.tar.gz_MD5 
done
