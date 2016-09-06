#Verify with MD5Sum check?
#!/bin/bash 

configSlicerJar='/opt/gls/clarity/tools/config-slicer/config-slicer-3.0.24.jar'
javaBinary='/opt/gls/jdk8/current/bin/java'

workflows=(
    "TruSeq Nano Half [v1.2]" 
    "SureSelect Half"
)
servers=(
    "roflms801a"
    "roflms701a"
    "roflms201a"
)

#########GATHER INFORMATION##########
# Select a workflow on commandline 
PS3='Please select a workflow to promote: '
select workflow in "${workflows[@]}";
do break; done

# Select source server on commandline One of : roflms[278]01a
PS3='Please select a server to promote from: '
select srcHost in "${servers[@]}";
    do 
    srcHost="$srcHost.mayo.edu"
    break; 
done

# Select source server on commandline One of : roflms[278]01a
PS3='Please select a server to promote to: '
#TODO Force this to be promoted one level
select dstHost in "${servers[@]}";
    do 
    dstHost="$dstHost.mayo.edu"
    break; 
done

# Get username
echo -n 'Enter API username: '
read user      

# Get password
echo -n 'Enter API password: '
read -s pass   
echo ''

#Get timestamp for filenames
date=$(date +%y%m%d-%H%M%S)

#What branch am I in?

#########BUILD MANIFEST FILE#########
echo ""
echo ""
echo "Generatig Manifest File"
echo ""
manifestFileNm="$workflow-$date-Manifest.xml"

manifestCmd="$javaBinary -jar $configSlicerJar  \
	 -u $user \
	 -p $pass \
	 -s $srcHost \
	 -o custom \
	 -w '$workflow' \
	 -m '$manifestFileNm' "
echo $manifestCmd
eval $manifestCmd

#Add Container UDF information that doesn't get pulled with -w
cat << HEREDOC >> "/opt/gls/clarity/tools/config-slicer/$manifestFileNm"
 # Manifest for Container UDFs
  ContainerUDFs=\ 
  Workflow-YYMM        
HEREDOC



#########BUILD Configuration FILE#########
echo ""
echo ""
echo "Generating Configuration File"
echo ""
configurationFileNm="$workflow-$date-Configuration.xml"
exportCmd="$javaBinary -jar $configSlicerJar  \
	 -u $user \
	 -p $pass \
	 -s $srcHost \
	 -o export \
	 -w '$workflow' \
	 -m '$manifestFileNm'\
	 -k '$configurationFileNm'"
eval $exportCmd



#########Upload Configuration to Destination#########
echo ""
echo ""
echo "Uploading Configuration to $dstHost"
echo ""
$javaBinary \
	-jar $configSlicerJar  \
  	-u $user \
	-p $pass \
	-s $dstHost \
	-k '$configurationFileNm'
	-o import


#########Validate Configuration#########
echo ""
echo ""
echo "Verification of Configuration"
echo ""
$javaBinary \
	-jar $configSlicerJar  \
  	-u $user \
	-p $pass \
	-s $dstHost \
	-k '$configurationFileNm'
	-o validate


#TODO Perform Manually
#Copy code from ssh://$srcHost/opt/gls/clarity/customextensions to ssh://$dstHost/opt/gls/clarity/customextensions
#Push code to TFS Git repository
#Create Git label/flag/branch to flag release if promoting to PROD (R1.1 R2.0 R3.0a)
#Create Git label/flag/branch to flag release+promotion cycle if promoting to INT (INT1.0C001)

