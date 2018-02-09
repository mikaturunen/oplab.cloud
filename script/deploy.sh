#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

SOURCE_BRANCH="master"
TARGET_BRANCH="gh-pages"
TARGET_DIR='out'

function doCompile {
  gem install bundler
  bundle install
  bundle exec jekyll build
}

# Pull requests and commits to other branches shouldn't try to deploy, just build to verify
if [ "$TRAVIS_PULL_REQUEST" != "false" -o "$TRAVIS_BRANCH" != "$SOURCE_BRANCH" ]; then
    echo "Skipping deployment, just doing a build."
    doCompile
    exit 0
fi

# Save some useful information
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}
SHA=`git rev-parse --verify HEAD`

echo '1. Listing current directory before gh-pages git clone.'
ls . | wc -l

# Clone the existing gh-pages for this repo into gh-pages/
# Create a new empty branch if gh-pages doesn't exist yet (should only happen on first deply)
echo 'Cloning gh-pages branch from repo'
pwd

git clone $REPO $TARGET_DIR
cd $TARGET_DIR
pwd
git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH
cd ..

echo '2. Listing current directory.'
pwd
ls . | wc -l

# Clean out existing contents
echo '3. Emptying $TARGET_DIR directory of existing content.'
pwd
ls $TARGET_DIR | wc -l

echo '4. Compiling jekyll project into _site that we can use to fill gh-pages directory.'
pwd
# Run our compile script
doCompile

echo 'Count in current directory'
pwd
ls . | wc -l

echo '5. Moving files from _site/ to gh-pages/'
pwd
# move files from generated _site/ into gh-pages and push them
rm -r $TARGET_DIR/assets
rm -r $TARGET_DIR/script
rm -r _site/out
mv _site/* $TARGET_DIR

ls $TARGET_DIR | wc -l

# Now let's go have some fun with the cloned repo
cd $TARGET_DIR
pwd
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# If there are no changes to the compiled out (e.g. this is a README update) then just bail.
if git diff --quiet; then
    echo "No changes to the output on this push, exiting."
    exit 0
fi

echo 'All is well, commiting!'
pwd

# Commit the "changes", i.e. the new version.
# The delta will show diffs between new and old versions.
git add -A .
git commit -m "Deploy to GitHub Pages: ${SHA}"

# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in ../deploy_key.enc -out ../deploy_key -d
chmod 600 deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

# Now that we're all set up, we can push.
git push $SSH_REPO $TARGET_BRANCH