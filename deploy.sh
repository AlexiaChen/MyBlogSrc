
#blog 自动化备份更新部署

blogTargetFiles="$HOME/Desktop/buildblog/blog/blog/*"
blogTarget="$HOME/Desktop/buildblog/blog/blog"
blogHome="$HOME/Desktop/buildblog/blog/"
blogSrc="$HOME/Desktop/buildblog/src"
blogSrcGen="$HOME/Desktop/buildblog/src/public/*"

cd $blogSrc

hexo clean

git add --all .

git commit -m"udpate blog"
git push -u git@github.com:AlexiaChen/MyBlogSrc.git master

hexo generate

rm -rf $blogTargetFiles
cp -r $blogSrcGen $blogTarget


cd $blogHome

git add --all .
git commit -m"update blog"
git push -u git@github.com:AlexiaChen/AlexiaChen.github.io.git master

echo "finished"


