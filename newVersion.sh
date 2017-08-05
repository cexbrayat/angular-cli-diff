#!/bin/bash

versions=$(npm view @angular/cli versions)

versions=${versions//\'/}
versions=${versions//\[/}
versions=${versions//\]/}
versions=${versions//\,/}

versions=(${versions})

blacklist=(1.0.0-beta.28.3 1.0.0-beta.29 1.0.0-beta.30 1.0.0-beta.31 1.0.0-beta.32
1.0.0-beta.32.2 1.0.0-beta.32.3 1.0.0-beta.33 1.0.0-beta.33.1
1.0.0-rc.0 1.0.0-rc.1 1.0.0-rc.2 1.0.0-rc.3 1.0.0-rc.4
1.3.0-rc.4)
lastVersion="1.0.0"

for version in "${versions[@]}"
do

  if [[ " ${blacklist[@]} " =~ " ${version} " ]]
  then
    echo "Skipping blacklisted ${version}"
    continue
  fi

  if [ `git branch --list ${version} ` ]
  then
    echo "${version} already generated."
    continue
  fi

  echo "Generate ${version}"
  git checkout -b ${version}
  # delete app
  rm -rf ponyracer
  # generate app with new CLI version
  npx @angular/cli@${version} new ponyracer --skip-install
  git add ponyracer
  diffStat=`git --no-pager diff HEAD~1 --shortstat`
  git commit -am "chore: version ${version}"
  git push origin ${version} -f
  git checkout master
  diffUrl="[${lastVersion}...${version}](https://github.com/cexbrayat/angular-cli-diff/compare/${lastVersion}...${version})"
  patchUrl="[${lastVersion}...${version}](https://github.com/cexbrayat/angular-cli-diff/compare/${lastVersion}...${version}.diff)"
  # insert a row in the version table of the README
  sed -i '' 's/----|----|----|----/----|----|----|----\
  NEWLINE/g' README.md
  sed -i "" "s@NEWLINE@${version}|${diffUrl}|${patchUrl}|${diffStat}@" README.md
  # commit
  git commit -am "chore: version ${version}"
  lastVersion=${version}

done
