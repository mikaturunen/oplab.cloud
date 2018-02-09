#!/bin/bash
set -e # Exit with nonzero exit code if anything fails

SOURCE_BRANCH="master"
TARGET_BRANCH="gh-pages"
TARGET_DIR='out'

function doCompile {
  ./script/bootstrap
  ./script/cibuild
  ls -la _site/
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

echo 'Listing current directory before gh-pages git clone.'
ls -la .

# Clone the existing gh-pages for this repo into gh-pages/
# Create a new empty branch if gh-pages doesn't exist yet (should only happen on first deply)
echo 'Cloning gh-pages branch from repo'
git clone $REPO $TARGET_DIR
cd $TARGET_DIR
git checkout $TARGET_BRANCH || git checkout --orphan $TARGET_BRANCH
cd ..

echo 'Listing current directory.'
ls -la .

# Clean out existing contents
echo 'Emptying ${TARGET_DIR} directory of existing content.'
rm -rf $TARGET_DIR/**/* || exit 0
ls -la $TARGET_DIR

echo 'Compiling jekyll project into _site that we can use to fill gh-pages directory.'
# Run our compile script
doCompile

echo 'Listing current directory.'
ls -la .

echo 'Moving files from _site/ to gh-pages/'
# move files from generated _site/ into gh-pages and push them
mv _site/* $TARGET_DIR
ls -la $TARGET_DIR

# Now let's go have some fun with the cloned repo
cd $TARGET_DIR
git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"

# If there are no changes to the compiled out (e.g. this is a README update) then just bail.
if git diff --quiet; then
    echo "No changes to the output on this push, exiting."
    exit 0
fi

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
chmod 600 ../deploy_key
eval `ssh-agent -s`
ssh-add deploy_key

# Now that we're all set up, we can push.
git push $SSH_REPO $TARGET_BRANCH