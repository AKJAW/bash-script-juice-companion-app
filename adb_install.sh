#!/bin/bash
# ubuntu "#!/bin/bash"
# macOs "#!/bin/sh"

#to install the app, adb is needed in $PATH
#.../Android/SDK/platform-tools
#to open the app, aapt is needed in $PATH
#.../Android/SDK/build-tools/{VERSION}

#example use cases:
#./adb_install.sh -h -> Shows help screen
#./adb_install.sh -a gls -> Installs Production Goal Livescores
#./adb_install.sh -a gls -o -> Installs Production Goal Livescores and opens it
#./adb_install.sh -a goal -m -> Installs Mock Goal News
#./adb_install.sh -a goal -m -b -> Builds the mock version then installs it
#./adb_install.sh -> Asks for a correct app name and then installs the production version

declare -a appMap=(
    "ap=apple"
    "or=orange"
    "acl=appleCarrotLime"
)

app=""
isMock=false
buildTheApp=false
openTheApp=false
showHelp=false

while getopts "a:mboh" flag; do
  case "${flag}" in
    a) app="${OPTARG}" ;;
    m) isMock=true ;;
    b) buildTheApp=true ;;
    o) openTheApp=true ;;
    h) showHelp=true ;;
  esac
done

if [[ "$showHelp" == true ]]
then
    echo "Available flags:"
    echo "'-a app' what app to install"
    echo "'-m' use the mock version"
    echo "'-b' build the app"
    echo "'-o' open the app (only works if you add aapt to path)"
    exit 0
fi

setAppFolderName(){
    #make the user app $1 input lowercase
    appNameArgument=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    for i in "${!appMap[@]}"; do
      #split appMap element with "=" and assign them
      appShortcut=$(echo ${appMap[$i]} | cut -d'=' -f1)
      appFullName=$(echo ${appMap[$i]} | cut -d'=' -f2)
      if [[ "$appNameArgument" == "$appShortcut" ||
        "$appNameArgument" == "$appFullName" ]]
        then
            #set the return variable $2 (folderPrefix)
            eval "$2=$appFullName"
            break 1
      fi
    done
}

#if user input correct then set the folder name
folderPrefix=""
setAppFolderName $app folderPrefix

#while the user app input is not correct ask for a correct app
while [ -z "$folderPrefix" ]; do
    for i in "${!appMap[@]}"; do
        echo ${appMap[$i]}
    done
    read -p "Enter a shortcut or full name: " input
    setAppFolderName $input folderPrefix
done

if [[ "$isMock" == true ]]
then
    type="Mock"
else
    type="Production"
fi

if [[ "$buildTheApp" == true ]]
then
    appNameCapitalized="$(tr '[:lower:]' '[:upper:]' <<< ${folderPrefix:0:1})${folderPrefix:1}"
    buildCommand="./gradlew assemble${appNameCapitalized}${type}Debug"
    echo "running: $buildCommand"
    eval "$buildCommand"
fi

#check if folder path exists
appFolderPath="app/build/outputs/apk/$folderPrefix$type"
if [[ ! -d "$appFolderPath" ]]
then
    echo "$appFolderPath doesn't exist"
    exit 1
fi

#take the first apk from ls sorted with -t
appDebugFolder="$appFolderPath/debug"
fullFilePath=$(ls -t $appDebugFolder/*.apk | head -1)

#execute adb install -r on apk
echo "Installing $fullFilePath"
eval "adb install -r $fullFilePath"

if [[ "$openTheApp" == true ]]
then
    pkg=$(aapt dump badging $fullFilePath|awk -F" " '/package/ {print $2}'|awk -F"'" '/name=/ {print $2}')
    act=$(aapt dump badging $fullFilePath|awk -F" " '/launchable-activity/ {print $2}'|awk -F"'" '/name=/ {print $2}')
    eval "adb shell am start -n $pkg/$act"
fi