#Data Science Assignment

###**Initial Analysis**
After visually analyzing more than 1000 Rows in LibreOffice Calc, few anomalies which were found in data are

1. Customer Number Dealer is Not Present For Various Records
2. County is Not Present For Various Records
3. Various Zip Codes Which Are Entered Are Not Correct
4. Wrong Value Of Mileage is Present in Few Records(For Instance 2)
5. Part Numbers Are Not Present For Every OpCode(Not Sure Whether this is Anomaly)
6. Vehicle Category Missing For Every Record

###**Data Extraction**
Even though initial investigation of 1000 records did gave us idea about how data is structured
but to completely investigate And for building understanding for data, whole data file was 
extracted in SQL SERVER 2008.
BULK COPY PROGRAM(BCP) was used for transferring the data From TAB separated file to SQL DB.

#####*REQUIREMENTS*

A dummy table Named Dummy_Table which will hold the dump of  TAB separated File

#####*Commands Used*

bcp DW.dbo.DS3 in “/home/ubuntu/Downloads/DataDocument” -f Char.fmt -S <server_name> -U<user_name> -P<password>

###**Table Break Down**
|                    |                    |                    |                    |                    |
|--------------------|--------------------|--------------------|--------------------|--------------------|
|                    |                    |                    |                    |                    |
|                    |                    |                    |                    |                    |
|                    |                    |                    |                    |                    |
|                    |                    |                    |                    |                    |
|                    |                    |                    |                    |                    |
|                    |                    |                    |                    |                    |
###**Observation And Encoding**
On Analysing table after dump, it was found that 1 row was missing in the Database.In order to find out that row Dealer_Id and Ro_Number were exported from table Dummy_Table in file ServerDB.Dealer Id and Ro Number were also imported from TAB separated file using awk command in file LocalDB.After that both files were sorted and compared with **DIFF** command, it was found that row having **Dealer Id=51018** and **Ro Number='18079875'** was missing.On analysing that row, it was detected that it was the presence of non Ascii character at the end of Description 2 which prevented TAB for getting detected.


####*Character Encoding*

On further analysing File For Non ASCII Characters using Command  

LC_ALL=c grep --color='auto' -P -n "[\x80-\xFF]" RO_Example.tab>Output_File

it was concluded that 59 rows have non ASCII Characters and on searching those rows in DB,it was found that '?' was present in places of those characters.

Non Ascii Characters

1. -
2. ‡
3. ï

####*Solution*

Command “file -bi Output_File” gave output charset=unknown 8 bit,So in order for DB to render these characters, they should be converted to UTF-8

#####*Using Iconv Command*
iconv -f “ascii” -t “utf-8” Output_File>Converted_File

Output:illegal input sequence at position 498

Thus in order to decode this file, some other encoding has to be chosen.Since this file was being rendered clearly by Sublime-Text,Preferences of Sublime Text was observed ,and it was deduced that default option of Sublime text encoding is Windows-1252

iconv -f “windows-1252” -t “utf-8” Output_File>Converted_File

On Counting Number Of rows of Converted_File,only 16 rows were Obtained

####Python Script:

    import codecs 
    BLOCKSIZE = 1048576 # or some other, desired size in bytes 
    with codecs.open("Output_File", "r","windows 1252") as sourceFile: 
        with codecs.open("Converted_File" ,"w", "utf-8") as targetFile: 
            while True:
                contents = sourceFile.read(BLOCKSIZE) 
                if not contents: 
                break 
                targetFile.write(contents)```
            
Using Above Python Script,Converted_File Contains 59 rows, and it can be further used for transferring those records in DB,so that they can be rendered Properly.
            
###**HYPOTHESIS AND VALIDATIONS**

#####1. Hypothesis to be proven is  Ro_Number can Be Primary Key

**Validating Hypothesis**

    Select Count(Distinct Ro_Number) from Dummy Table

Output Obtained =768107.

Total Records Present =1857537

**41.358%** data Suggests that Ro_Number is unique.Rest of the data did not satisfy this relation, which is even less than half of the Total data present,Hence this hypothesis cannot be used while using this data .Hence this hypothesis is false.


#####2. Hypothesis to be proven is Customer_Num_Dealer is Unique Throughout


**Validating Hypothesis**

    Select Count(Distinct Customer_Num_Dealer) from Dummy Table

Output Obtained =372602 

Total Records Present =1857537

Nearly **20.0588%**  of the data have unique Customer_Num_Dealer .So if only that much amount of data is taken for consideration, only then this hypothesis would be true, otherwise based on above result, this hypothesis is false. 

######3. Hypothesis to be proven is Technician Data is Not Consistent

**Validating Hypothesis**

*Requirements:*

A table which will hold The Distinct Value of All The Technician_Numbers

    Create Table #NumberTech2
    (
    TECH_NAME VARCHAR(8000)
    )

    Insert Into #NumberTech2 
    
        Select  Distinct(i.items)
    
        From Dummy Table t1
    
        Outer Apply dbo.split(t1.Technician_Number, '^')i  
    
        Order by i.items

    select COUNT(*) as Total_Present from #NumberTech2 

`Total_Present=2450`

select COUNT(*) as Total_Obtained 

from #NumberTech2 

where ISNUMERIC(TECH_NAME)=0

`Total_Obtained=238`

Almost **9.714%** of the Technician_Number is not.Since this amount cannot be ignored and in order to further strengthen above fact, we would find out that whether all the VARCHAR Technician_Number is not restricted to only 1 or 2 Dealer, which would prove that it is not a typing mistake

    Select Count(Distinct Dealer_Id) as Dealer_Tech_Varchar  

    From Dummy Table 

    Where Technician_Number in(Select * 
                            
                                From #NumberTech2 
                            
                                Where ISNUMERIC(TECH_NAME)=0)

    Select 

    COUNT(Distinct Dealer_Id) as Total_Dealers 

    from Dummy Table

Output Obtained

`Dealer_Tech_Varchar=20`

`Total_Dealers=96`

Thus,Almost *20.833 %* of dealers Technician_Number consists of varchar, which is not confined to only 1 or 2 Dealer.Hence we can conclude from above Observation that, presence of characters in Technician_Number does not prove that data is inconsistent.Hence above Hypothesis has been proved false.

#####4. Hypothesis to be proven is Parts_Amount And Labour_Amount Is Split Up in Customer,Internal And Warranty Parts

*Requirements:*

A Dummy table Which contains all the fields corresponding To Amount.

    Create Table Amount_Fields_Table
    
    (
    
    Parts_Amount float,
    
    Labour_Amount float,
    
    Ro_Total float,
    
    Cus_Lab_Amount Float,
    
    Cut_Par_Amount float,
    
    Cust_Mis_Amount float,
    
    Warr_Labou_Amount float,
    
    Warr_Parts_Amount float ,
    
    Warr_Miss_Amount float,
    
    Inter_Labour_Amount float,
    
    Inter_Parts_Amount float,
    
    Inter_Misc float
    
    )



Validating Hypothesis

    a)Select * 
    From Amount_Fields_Table 
    Where Cus_Lab_Amount+Inter_Labour_Amount+Warr_Labou_Amount=Labour_Amount


    Select @@ROWCOUNT as Total_Values

`Output Obtained =1660592`

Only 89.3975% of records satisfy above Result.

When above column are *Cast*

    Select * 
    From Amount_Fields_Table
    where Cast(Cus_Lab_Amount as int)+cast(Inter_Labour_Amount as int)+Cast(Warr_Labou_Amount as int)=Cast(Labour_Amount as int)

    Select @@ROWCOUNT as Total_Values

`Total_Values=1752789`

Which is *94.3609%* of the total records.Though this result is better than the previous result, but sill it is not statistically close enough to prove that this relation exists throughout the data.Thus above hypothesis is false

Another point in Favour of proving this hypothesis false is

    Select 
    Count(Distinct(Dealer_Id)) 
    From Amount_Fields_Table 
    Where (Cast(Cus_Lab_Amount as int)+Cast(Inter_Labour_Amount as int)+Cast(Warr_Labou_Amount as int))!=Cast(Labour_Amount as int)

`Output Obtained =93`

Hence almost **96.875%** of the dealers contain data, which does not satisfy above result


    b)Select * 
    from Amount_Fields_Table 
    where
    Cus_Par_Amount +Inter_Parts_Amount +Warr_Parts_Amount=Parts_Amount

    Select @@ROWCOUNT as Total_Parts_Value

`Output Obtained =1701102`

Only **91.901372%** of records satisfy above Result

    Select * 
    From Amount_Fields_Table
    Where Cast(Cus_Par_Amount as int) +Cast(Inter_Parts_Amount as int) +Cast(Warr_Parts_Amount as int)=Cast(Parts_Amount as int)

    Select @@ROWCOUNT as Total_Parts_Value


`Output Obtained =1769887`
Which is **95.281%** of the Total Records.Though this Result is better than the previous Result,But sill it is not statistically close enough.

    Select Distinct(Dealer Id) 
    From Amount_Fields_Table
    Where (Cast(Cut_Par_Amount as int)+Cast(Inter_Parts_Amount as int)+Cast(Warr_Parts_Amount as int))!=Cast(Parts_Amount as int)

`Output Obtained =93`

Hence almost **96.875%** of the dealers contain data, which does not satisfy above result

Hence above Hypothesis that Parts Amount is split into Customer,Warranty and Internal Component is false

#####5.Hypothesis to be proven is Ro_Total Field is Split in Customer_Amount,Customer_Parts,Customer_Misc

*Validation*

    Select * 
    From Amount_Fields_Table
    Where Ro_Total=0 and (Cast(Cus_Lab_Amount as Int)+Cast(Cut_Par_Amount as Int)+Cast(Cust_Mis_Amount as Int) )=0	

  Select @@ROWCOUNT as Total_Results_Obtained

  Select * from Amount_Fields_Table where Ro_Total=0
  Select @@ROWCOUNT as Values_Present

`Total_Results_Obtained=838750`

`Values_Present=8389375`

Since The Above Result proves that almost **99.9255 %** records satisfy above condition,Hence Above Hypothesis is True.

###Different Criteria For Calculating Top Dealer

1. One of the criteria For calculating top Dealer could be by categorizing dealers by
  the `Count of Technicians` they possess.This criteria points in the direction of ability to
  handle various operations

2. Second criteria could be by calculating `Labour Time`,for every dealer, for some
  common operation.This could help in categorizing dealer on the basis of hiring/
  possession of efficient dealers

3. Third criteria could be by calculating Total Revenue ,that is sum of `Labour_Amount
   and Parts_Amount`.It divides dealers on the basis of Earnship

4. Fourth criteria could be by finding out `Total Expenditure` By Every Dealer.

5. Fifth criteria could be by calculating `Number Of Distinct Vehicles` visiting each Dealer.This criteria could point in the direction of Reliability of Every Dealer.


###SQL QUERIES FOR DIFFERENT CRITERIA

#####*Query To Fetch Number Of Technicians*

        Create Table #NumberTech
          (
          Dealer_Id INT,
          No_Of_Tech INT
          )

        Insert Into #NumberTech 
          Select  Case When ISNUMERIC(t1.Dealer_Id)=1 THEN CAST(t1.Dealer_Id as Int)ELSE NULL END,
          count(distinct i.items)
          From Dummy Table t1
          Outer Apply dbo.split(t1.Op_Codes, '^')i  group by Dealer_Id order by Count(distinct i.items)
  
        Select * 
        From #NumberTech

#####*Query To Find Labour Time For Common Occuring OpCode*
**Checking If Same Op_Codes Exist For Every Code In Order To Calculate Laboue_Time** 

    Create Table #SecondTemp
      (
      Dealer_Id INT,
      Op_Codes VARCHAR(8000)
      )

      Select 
        Dealer_Id,Op_Codes From Dummy Table 
        Group by Op_Codes,Dealer_Id 
        Order by Dealer_Id
    
    
      Insert Into #SecondTemp 
        Select Case When ISNUMERIC(Dealer_id)=1 THEN CAST(Dealer_Id as Int)ELSE NULL END , Op_Codes 
        From Dummy Table 
        Group by Op_Codes,Dealer_Id 
        Order by Dealer_Id

      Select Op_Codes,COUNT(*) 
      From #SecondTemp 
      Group by Op_Codes Having COUNT(*)>91

#####*Query For Finding Labour_Time For The Deduced Op_Code*

Creating Table For Op_Code=40 Present In All The Dealer_Id
       
    Create Table #LabourTime
    (
    Dealer_Id INT,
    Labour_Time Float
    )
    Insert Into #LabourTime Select distinct Dealer_Id,Labour_Time From DS3 where Op_Codes='40'

    Insert into #LabourTime 
      Select  Dealer_Id,SUM(CASE WHEN ISNUMERIC(Labour_Time)=1 THEN CONVERT(FLOAt,Labour_Time)ELSE NULL END) 
      From Dummt Table 
      Where Op_Codes='40' 
      Group by Dealer_Id

Delete From #LabourTime

    Select * from #LabourTime

#####*Query For Determining Number Of Distinct Vehicles*

Creating Table Which Stores The Count Of Each VIN in Every Dealer

    Create Table #ValCal
      (
      Dealer_Id INT,
      VIN VARCHAR(8000),
      Total_Rows INT
      )

--Drop Table #ValCal

    Insert Into #ValCal 
      Select  Case When ISNUMERIC(Dealer_id)=1 THEN CAST(Dealer_Id as Int)ELSE NULL END,VIN,COUNT(*) as Total_Rows 
      From Dummy Table 
      Group By VIN,Dealer_Id  
      Order By Dealer_Id

--Creating Table For Storing Dealer Id's Along With their Number Of Distinct Vehicles

    Create Table #DisVeh
      (
      Dealer_Id INT,
      Total_Distinct_Vehicle INT
      )
 
    Insert Into #DisVeh Select Dealer_Id,COUNT(*) from #ValCal  group by Dealer_Id

#####*Query To Fetch Revenue Generated For Every Dealer*

--Creating Table to store Revenue generated by every dealer

    Create Table #Revenue
      (
      Dealer_Id INT,
      Labour_Amount Float,
      Parts_Amount Float
      )

    Insert Into #Revenue 
      Select Case When ISNUMERIC(Dealer_id)=1 THEN CAST(Dealer_Id as Int)ELSE NULL END,SUM(CASE WHEN ISNUMERIC(Labour_Amount)=1 THEN CONVERT(FLOAt,Labour_Amount)ELSE NULL END),SUM(CASE WHEN ISNUMERIC(Parts_Amount)=1 THEN CONVERT(FLOAT,Parts_Amount) ELSE NULL END)
      From Dummy Table 
      Group By Dealer_Id  


    Create Table #Rev_Final
      (
      Dealer_Id INT,
      Total_Revenu Float
      )

    Insert Into #Rev_Final 
      Select Dealer_Id,Labour_Amount +Parts_Amount  
      From #Revenue

#####*Query To Fetch Expenditure For Every Dealer*

--Splitting Labour_Op Per Dealer

    Create Table #Labour_Per_Op
      (Dealer_Id Int,
      Labour_Per_Op Float
      )


    Insert Into #Labour_Per_Op  
      Select Case When ISNUMERIC(Dealer_id)=1 THEN CAST(Dealer_Id as Int)ELSE NULL END,SUM(CASE WHEN ISNUMERIC(i.items)=1 THEN CONVERT(FLOAt,i.items)ELSE NULL END)
      From Dummy Table t1
      outer apply dbo.split(t1.Labor_Per_Op, '^')i  
      Group By Dealer_Id
      

--Splitting Parts_Op Per Dealer

    Create Table #Parts_Per_Op
      (Dealer_Id Int,
      Parts_Per_Op Float
      )
    Insert Into #Parts_Per_Op  
      Select Case When ISNUMERIC(Dealer_id)=1 THEN CAST(Dealer_Id as Int)ELSE NULL END,SUM(CASE WHEN ISNUMERIC(i.items)=1 THEN CONVERT(FLOAt,i.items)ELSE NULL END)
      From Dummy Table t1
      outer apply dbo.split(t1.Parts_Per_Op, '^')i  
      Group By Dealer_Id 

--Creating Table Which Would Contain The Sum Of  Lavour_Per_Op And Parts_Per_Op

    Create Table #Exp_Final
      (
      Dealer_Id Int,
      Total_Expend Float
      )

    Insert Into  #Exp_Final(Dealer_Id) 
      Select Dealer_Id from #Labour_Per_Op 

--Joining Above Created Tables To Fill Final Table

    Update #Exp_Final 
    Set Total_Expend=#Labour_Per_Op.Labour_Per_Op+#Parts_Per_Op.Parts_Per_Op 
    From #Labour_Per_Op,#Parts_Per_Op,#Exp_Final 
    Where #Exp_Final.Dealer_Id=#Labour_Per_Op.Dealer_Id and #Exp_Final.Dealer_Id=#Parts_Per_Op.Dealer_Id



