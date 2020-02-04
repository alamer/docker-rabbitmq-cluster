FROM rabbitmq:3.8.2-management as base
RUN rabbitmq-plugins enable --offline rabbitmq_mqtt rabbitmq_stomp rabbitmq_management  rabbitmq_management_agent rabbitmq_federation rabbitmq_federation_management
ADD startrabbit.sh /opt/rabbit/

RUN mkdir -p /opt/rabbit \
&& chmod a+x /opt/rabbit/startrabbit.sh

EXPOSE 5672 15672 25672 4369 9100 9101 9102 9103 9104 9105

CMD ["/opt/rabbit/startrabbit.sh"]