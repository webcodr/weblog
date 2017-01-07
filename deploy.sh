echo '[hugo deployment] start deployment'
echo '[hugo deployment] Run hugo'
hugo > /dev/null
echo '[hugo deployment] clone github.io page repo'
git clone git@github.com:WebCodr/WebCodr.github.io.git deployment --quiet > /dev/null
echo '[hugo deployment] Copy new stuff'
cp -rf public/* deployment/ 
cd deployment
echo '[hugo deployment] commit and push new stuff'
git add -A > /dev/null
git commit -m "Update blog" --quiet > /dev/null
git push --quiet > /dev/null
cd ..
rm -rf deployment
echo '[hugo deployment] end deployment'
