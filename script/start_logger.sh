#echo 'require "./script/logreader.rb"' | ./script/console

nohup ./script/logreader /var/log/apache2/stats.crumbtrail/access.log &