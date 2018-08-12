
#blog 自动化备份更新部署

blogTargetFiles="$HOME/build-blog/AlexiaChen.github.io/blog/*"
blogTarget="$HOME/build-blog/AlexiaChen.github.io/blog"
blogHome="$HOME/build-blog/AlexiaChen.github.io/"
blogSrc="$HOME/build-blog/src"
blogSrcGen="$HOME/build-blog/src/public/*"

cd $blogSrc

hexo clean



hexo generate

rm -rf $blogTargetFiles
cp -r $blogSrcGen $blogTarget


cd $blogHome

git add --all .
git commit -m"update blog"
git push -u origin master

echo "finished"


