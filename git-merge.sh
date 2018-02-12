#!/bin/bash

INCLUDE_API=false;
INCLUDE_WEB=false;
INCLUDE_LANDING=false;

API_VERSION="";
WEB_VERSION="";
LANDING_VERSION="";

SHIP_VERSION="";

rm -rf ./temp_repos
mkdir ./temp_repos
cd ./temp_repos

shipRepository="https://github.com/paralect/ship"
reactRepository="https://github.com/paralect/koa-react-starter"
apiRepository="https://github.com/paralect/koa-api-starter"
landingRepository="https://github.com/paralect/nextjs-landing-starter"

shipPath="ship"
reactPath="koa-react-starter"
apiPath="koa-api-starter"
landingPath="nextjs-landing-starter"

environmentPaths=( "web/src/server/config/environment"
                   "api/src/config/environment"
                   "landing/src/server/config/environment" )

filesToRemove=( ".drone.yml"
                "docker-compose.yml"
                "LICENSE"
                "CHANGELOG.md"
                "CODE_OF_CONDUCT.md"
                ".all-contributorsrc"
                "CONTRIBUTING.md"
                "README.md"
                "package-lock.json" )

repositoryActions() {
  declare -a files=("${!4}")
  cd ./$1
  
  echo "### $1 ###"

  if [ "$2" != "master" ]
  then
    git checkout tags/$2
  fi

  echo "=== START REMOVE UNNECESSARY FILES FROM HISTORY ==="
  
  git filter-branch --tree-filter "
    GLOBIGNORE='n*';
    rm ${files[*]};
    mv SHIP_README.md README.md
    sed -i '/all-contributor/d' package.json
    sed -zri 's/,\n  }/\n  }/g' package.json
    mkdir -p ../temp_path;
    mv * ../temp_path;
    mkdir $3;
    mv ../temp_path/* $3/;
    unset GLOBIGNORE;
  " --force --prune-empty HEAD
  
  git branch -D master
  git checkout -b master
  echo "=== DONE REMOVE FILES FROM HISTORY ==="

  cd ../
}

cloneRepository() {
  echo "=== CLONE REPOSITORY $1 ==="
  git clone $1
  echo "=== DONE CLONE REPOSITORY $1 ==="
}

copyCommitsToShip() {
  echo "=== START COPY COMMITS TO THE SHIP REPOSITORY from $1 ==="
  cd ./$shipPath
      
  git remote add repo-$1 ../$1/.git
  git pull repo-$1 master --allow-unrelated-histories --no-edit
  git remote rm repo-$1

  echo "=== END COPY COMMITS ==="
  cd ../
}

parseYaml() {
  local prefix=$2
  local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
  sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
    -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
  awk -F$fs '{
    indent = length($1)/2;
    vname[indent] = $2;
    for (i in vname) {if (i > indent) {delete vname[i]}}
    if (length($3) > 0) {
        vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
        printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
    }
  }'
}

regeneratePackageLock() {
  cd ./$1
  # Remove all contributors from package-lock.json
  rm package-lock.json
  npm i --quiet

  cd ../
}

cloneRepository $shipRepository

echo "=== PARSE release.yml FILE ==="
cd ./$shipPath
eval $(parseYaml release.yml "config_")
cd ../

INCLUDE_API=$config_services_api_include;
INCLUDE_WEB=$config_services_web_include;
INCLUDE_LANDING=$config_services_landing_include;

SHIP_VERSION=$config_services_ship_version;
API_VERSION=$config_services_api_version;
WEB_VERSION=$config_services_web_version;
LANDING_VERSION=$config_services_landing_version;

echo "=== END PARSE FILE ==="

# cd ./$shipPath
# git filter-branch --tree-filter "rm -rf ./api ./web ./landing;" --force --prune-empty HEAD
# cd ../

if [ "$INCLUDE_API" = true ]
then
  cloneRepository $apiRepository

  if [ "$API_VERSION" = "latest" ]
  then
    cd ./$apiPath
    API=$(git describe --tags `git rev-list --tags --max-count=1`)
    cd ../
  fi

  repositoryActions $apiPath $API_VERSION "api" filesToRemove[@]
  copyCommitsToShip $apiPath
fi

if [ "$INCLUDE_WEB" = true ]
then
  cloneRepository $reactRepository

  if [ "$WEB_VERSION" = "latest" ]
  then
    cd ./$reactPath
    WEB=$(git describe --tags `git rev-list --tags --max-count=1`)
    cd ../
  fi

  repositoryActions $reactPath $WEB_VERSION "web" filesToRemove[@]
  copyCommitsToShip $reactPath
fi

if [ "$INCLUDE_LANDING" = true ]
then
  cloneRepository $landingRepository

  if [ "$LANDING_VERSION" = "latest" ]
  then
    cd ./$landingPath
    LANDING=$(git describe --tags `git rev-list --tags --max-count=1`)
    cd ../
  fi

  repositoryActions $landingPath $LANDING_VERSION "landing" filesToRemove[@]
  copyCommitsToShip $landingPath
fi

echo "=== COPY STAGING ENVIRONMENT FILE ==="
for envPath in ${environmentPaths[@]}
do
  cp ../../staging.js "./$envPath/staging.js"
done
echo "=== DONE COPY STAGING ENVIRONMENT FILE ==="

sed -i "1s/^/  3) web version [$WEB_VERSION](https:\/\/github.com\/paralect\/koa-react-starter\/releases\/tag\/$WEB_VERSION)\n\n/" CHANGELOG.md
sed -i "1s/^/  2) landing version [$LANDING_VERSION](https:\/\/github.com\/paralect\/nextjs-landing-starter\/releases\/tag\/$LANDING_VERSION)\n/" CHANGELOG.md
sed -i "1s/^/  1) api version [$API_VERSION](https:\/\/github.com\/paralect\/koa-api-starter\/releases\/tag\/$API_VERSION)\n/" CHANGELOG.md
sed -i "1s/^/* New release of ship with the following components:\n/" CHANGELOG.md

releaseDate=`date '+%B %d, %Y'`;
sed -i "1s/^/## $SHIP_VERSION ($releaseDate)\n\n/" CHANGELOG.md

regeneratePackageLock "api"
regeneratePackageLock "web"
regeneratePackageLock "landing"

git add -A;
git commit -m "Version $SHIP_VERSION";
git tag $SHIP_VERSION;

git remote set-url origin git@github.com:paralect/ship
