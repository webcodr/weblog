hugo
git clone git@github.com:WebCodr/WebCodr.github.io.git deployment
cp -rf public/* deployment/
cd deployment
git add -A
git commit -m "Update blog"
git push
cd ..
rm -rf deployment
