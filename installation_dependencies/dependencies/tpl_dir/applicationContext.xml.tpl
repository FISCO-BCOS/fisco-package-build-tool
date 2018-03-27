<?xml version="1.0" encoding="UTF-8" ?>

<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:p="http://www.springframework.org/schema/p"
	xmlns:tx="http://www.springframework.org/schema/tx" xmlns:aop="http://www.springframework.org/schema/aop"
	xmlns:context="http://www.springframework.org/schema/context"
	xsi:schemaLocation="http://www.springframework.org/schema/beans   
    http://www.springframework.org/schema/beans/spring-beans-2.5.xsd  
         http://www.springframework.org/schema/tx   
    http://www.springframework.org/schema/tx/spring-tx-2.5.xsd  
         http://www.springframework.org/schema/aop   
    http://www.springframework.org/schema/aop/spring-aop-2.5.xsd">
    
    <bean id="pool" class="org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor">
		<property name="corePoolSize" value="50" />
		<property name="maxPoolSize" value="100" />
		<property name="queueCapacity" value="500" />
		<property name="keepAliveSeconds" value="60" />
		<property name="rejectedExecutionHandler">
			<bean class="java.util.concurrent.ThreadPoolExecutor.AbortPolicy" />
		</property>
    </bean>

	<bean id="toolConf" class="cn.webank.contract.tools.ToolConf">
		<property name="systemProxyAddress" value="${JTOOL_SYSTEM_CONTRACT_ADDR}" />
		<property name="outPutpath" value="./output/" />
	</bean>

	<bean id="channelService" class="cn.webank.channel.client.Service">
		<property name="orgID" value="WB" />
		<property name="connectSeconds" value="10" />
		<property name="connectSleepPerSeconds" value="10" />
		<property name="allChannelConnections">
			<map>
				<entry key="WB">
					<bean class="cn.webank.channel.handler.ChannelConnections">
                        <property name="connectionsStr">
							<list>
								<value>node1@127.0.0.1:${JTOOL_CONFIG_PORT}</value>
							</list>
						</property>
                    </bean>
				</entry>
			</map>
		</property>
	</bean>
</beans>