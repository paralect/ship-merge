#!/bin/bash

rm -rf ./temp_repos
mkdir ./temp_repos
cd ./temp_repos

repositories=( "https://github.com/paralect/ship"
               "https://github.com/paralect/koa-react-starter"
               "https://github.com/paralect/koa-api-starter"
               "https://github.com/paralect/nextjs-landing-starter" )

paths=( "koa-react-starter"
        "koa-api-starter"
        "nextjs-landing-starter" )

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
  declare -a files=("${!3}")
  cd ./$1
  
  echo "### $1 ###"

  echo "=== CHECKOUT TO THE LATEST TAG ==="
  tags=($(git tag))

  if [ ${#tags[@]} -gt 0 ]
  then
      latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)
      git checkout tags/${latestTag}
  fi
  echo "=== DONE CHECKOUT ==="

  echo "=== START REMOVE UNNECESSARY FILES FROM HISTORY ==="
  
  git filter-branch --tree-filter "
    GLOBIGNORE='n*';
    rm ${files[*]};
    mv SHIP_README.md README.md
    sed -i '/all-contributor/d' package.json
    mkdir -p ../temp_path;
    mv * ../temp_path;
    mkdir $2;
    mv ../temp_path/* $2/;
    unset GLOBIGNORE;
  " --force HEAD
  
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
}

echo "=== CLONE REPOSITORIES ==="
for element in ${repositories[@]}
do
  echo "clonning $element"
  git clone $element
done
echo "=== DONE CLONE REPOSITORIES ==="

repositoryActions ${paths[0]} "web" filesToRemove[@]
repositoryActions ${paths[1]} "api" filesToRemove[@]
repositoryActions ${paths[2]} "landing" filesToRemove[@]

removeAllContributors ${paths[0]} "web"
removeAllContributors ${paths[1]} "api"
removeAllContributors ${paths[2]} "landing"

echo "=== START COPY COMMITS TO THE SHIP REPOSITORY ==="
cd ./ship

git filter-branch --tree-filter "rm ./api ./web ./landing;" --force HEAD
    
for path in ${paths[@]}
do
  git remote add repo-$path ../$path/.git
  git pull repo-$path master --allow-unrelated-histories --no-edit
  git remote rm repo-$path
done
echo "=== END COPY COMMITS ==="
cd ../../

echo "=== COPY STAGING ENVIRONMENT FILE ==="
for envPath in ${environmentPaths[@]}
do
  cp ./staging.js "./temp_repos/ship/$envPath/staging.js"
done
echo "=== DONE COPY STAGING ENVIRONMENT FILE ==="
