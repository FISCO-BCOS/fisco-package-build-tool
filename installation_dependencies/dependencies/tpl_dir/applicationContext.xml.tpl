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

	<bean id="encryptType" class="org.bcos.web3j.crypto.EncryptType">
		<constructor-arg value="0"/>
	</bean>

	<bean id="toolConf" class="org.bcos.contract.tools.ToolConf">
		<property name="systemProxyAddress" value="${JTOOL_SYSTEM_CONTRACT_ADDR}" />
		<property name="privKey" value="bcec428d5205abe0f0cc8a734083908d9eb8563e31f943d760786edf42ad67dd" />
		<property name="account" value="0x776bd5cf9a88e9437dc783d6414bccc603015cf0" />
		<property name="outPutpath" value="./output/" />
	</bean>
	
	<bean id="channelService" class="org.bcos.channel.client.Service">
		<property name="orgID" value="WB" />
		<property name="connectSeconds" value="100" />
		<property name="connectSleepPerMillis" value="10" />
		<property name="allChannelConnections">
			<map>
				<entry key="WB">
					<bean class="org.bcos.channel.handler.ChannelConnections">
						<property name="caCertPath" value="classpath:ca.crt" />
						<property name="clientKeystorePath" value="classpath:client.keystore" />
						<property name="keystorePassWord" value="123456" />
						<property name="clientCertPassWord" value="123456" />
                        <property name="connectionsStr">
							<list>
								<value>node1@${JTOOL_CONFIG_IP}:${JTOOL_CONFIG_PORT}</value>  
							</list>
						</property>
                    </bean>
				</entry>
			</map>
		</property>
	</bean>
</beans>
