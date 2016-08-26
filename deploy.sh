
#blog 自动化备份更新部署

blogTargetFiles="$HOME/Desktop/myblog/blog/*"
blogTarget="$HOME/Desktop/myblog/blog"
blogHome="$HOME/Desktop/myblog"
blogSrc="$HOME/Desktop/blogsrc"

cd $blogSrc

hexo clean

git add --all .

git commit -m"udpate blog"
git push -u git@github.com:AlexiaChen/MyBlogSrc.git master

hexo generate

rm -rf $blogTargetFiles
cp ./public/* $blogTarget


cd $blogHome

git add --all .
git commit -m"update blog"
git push -u git@github.com:AlexiaChen/AlexiaChen.github.io.git master

echo "finished"


