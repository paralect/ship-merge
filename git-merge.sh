#!/bin/bash

API=$false;
WEB=$false;
LANDING=$false;

while getopts a:w:l: option
do
 case "${option}"
 in
 a) API=${OPTARG};;
 r) WEB=${OPTARG};;
 l) LANDING=${OPTARG};;
 esac
done

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
                "README.md" )

repositoryActions() {
  declare -a files=("${!4}")
  cd ./$1
  
  echo "### $1 ###"

  if [ $2 -ne "master" ]
    git checkout tags/$2
  fi

  echo "=== START REMOVE UNNECESSARY FILES FROM HISTORY ==="
  
  git filter-branch --tree-filter "
    GLOBIGNORE='n*';
    rm ${files[*]};
    mv SHIP_README.md README.md
    sed -i '/all-contributor/d' package.json
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

removeAllContributors() {
  cd ./$1/$2
  # Remove all contributors from package.json
  sed -i -e '/all-contributor/d; :a;N;$!ba;s/,\n  }/\n  }/g' package.json
  rm package-lock.json
  npm i --quiet

  cd ../
  git add -A
  git commit -m "remove contributors"
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

cloneRepository $shipRepository
if [ $API -ne $false ]
then
  cloneRepository $apiRepository

  if [ $API -eq "latest" ]
  then
    cd ./$apiPath
    API=$(git describe --tags `git rev-list --tags --max-count=1`)
    cd ../
  fi

  repositoryActions $apiPath $API "api" filesToRemove[@]
  removeAllContributors $apiPath "api"
  copyCommitsToShip $apiPath
fi

if [ $WEB -ne $false ]
then
  cloneRepository $reactRepository

  if [ $WEB -eq "latest" ]
  then
    cd ./$reactPath
    WEB=$(git describe --tags `git rev-list --tags --max-count=1`)
    cd ../
  fi

  repositoryActions $reactPath $WEB "web" filesToRemove[@]
  removeAllContributors $reactPath "web"
  copyCommitsToShip $reactPath
fi

if [ $LANDING -ne $false ]
then
  cloneRepository $landingRepository

  if [ $LANDING -eq "latest" ]
  then
    cd ./$landingPath
    LANDING=$(git describe --tags `git rev-list --tags --max-count=1`)
    cd ../
  fi

  repositoryActions $landingPath $LANDING "landing" filesToRemove[@]
  removeAllContributors $landingPath "landing"
  copyCommitsToShip $landingPath
fi

cd ../

echo "=== COPY STAGING ENVIRONMENT FILE ==="
for envPath in ${environmentPaths[@]}
do
  cp ./staging.js "./temp_repos/ship/$envPath/staging.js"
done
echo "=== DONE COPY STAGING ENVIRONMENT FILE ==="
