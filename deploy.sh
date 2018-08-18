
#backup and deploy automically for my blog

blogTargetFiles="$HOME/build-blog/AlexiaChen.github.io/blog/*"
blogTarget="$HOME/build-blog/AlexiaChen.github.io/blog"
blogHome="$HOME/build-blog/AlexiaChen.github.io/"
blogSrc="$HOME/build-blog/src"
blogSrcGen="$HOME/build-blog/src/public/*"

blogSrcBakup="$HOME/build-blog/MyBlogSrcBak"

cd $blogSrc

echo "starting deploy"

hexo clean



hexo generate

rm -rf $blogTargetFiles
cp -r $blogSrcGen $blogTarget


cd $blogHome

git add --all .
git commit -m"deploy and update blog"
git push -u origin master

echo "deploy finished"

echo "starting backup"

cp -ar $blogSrc/source $blogSrcBakup
cp -ar $blogSrc/themes $blogSrcBakup
cp -ar $blogSrc/_config.yml $blogSrcBakup
cp -ar $blogSrc/deploy.sh $blogSrcBakup

cd $blogSrcBakup

git add --all .
git commit -m"backup blog"
git push -u origin master

cd $blogSrc

echo "backup finished"