#!/bin/bash

change_default_user() {
	
	if [ -z $RABBITMQ_DEFAULT_USER ] && [ -z $RABBITMQ_DEFAULT_PASS ]; then
		echo "Maintaining default 'guest' user"
	else 
		echo "Removing 'guest' user and adding ${RABBITMQ_DEFAULT_USER}"
		rabbitmqctl delete_user guest
		rabbitmqctl add_user $RABBITMQ_DEFAULT_USER $RABBITMQ_DEFAULT_PASS
		rabbitmqctl set_user_tags $RABBITMQ_DEFAULT_USER administrator
		rabbitmqctl set_permissions -p / $RABBITMQ_DEFAULT_USER ".*" ".*" ".*"
	fi
}

foreground_active() {
	while ps axg | grep -vw grep | grep -w rabbitmq-server > /dev/null; do sleep 1; done
}

HOSTNAME=`env hostname`

if [ -z "$CLUSTERED" ]; then
	# if not clustered then start it normally as if it is a single server
	/opt/rabbitmq/sbin/rabbitmq-server &
	rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid
	change_default_user	
	RUN rabbitmqctl set_policy HA ".*" "{""ha-mode"": ""all""}"
	# keep the a foreground process active..
	foreground_active
else
	if [ -z "$CLUSTER_WITH" ]; then
		# If clustered, but cluster with is not specified then again start normally, could be the first server in the
		# cluster
		/opt/rabbitmq/sbin/rabbitmq-server &
		rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid
		RUN rabbitmqctl set_policy HA ".*" "{""ha-mode"": ""all""}"
		# keep the a foreground process active..
		foreground_active
	else
		/opt/rabbitmq/sbin/rabbitmq-server &
		rabbitmqctl wait /var/lib/rabbitmq/mnesia/rabbit\@$HOSTNAME.pid
		rabbitmqctl stop_app
		if [ -z "$RAM_NODE" ]; then
			rabbitmqctl join_cluster rabbit@$CLUSTER_WITH
		else
			rabbitmqctl join_cluster --ram rabbit@$CLUSTER_WITH
		fi
		rabbitmqctl start_app                		
		RUN rabbitmqctl set_policy HA ".*" "{""ha-mode"": ""all""}"
		# keep the a foreground process active..
		foreground_active
	fi
fi