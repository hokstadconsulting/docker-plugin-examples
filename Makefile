
PLUGIN=vidarh

install:
	sudo mkdir -p /etc/docker/plugins
	sudo cp ${PLUGIN}.json /etc/docker/plugins/

bundle:
	bundle install --path=vendor/bundle

run:
	ruby plugin.rb

pry:
	bundle exec pry 
