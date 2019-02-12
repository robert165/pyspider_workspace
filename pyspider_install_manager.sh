#!/bin/bash
#	liu,yu 2018-05-22 
#	V 1.0.0
#描述：部署工程pyspider的docker和添加volume，步骤如下：
#1.地址：显示当前IP等信息，询问是否更改(未完成)
#2.用户：是否切换或创建用户，是则创建并切换到新用户（未完成）
#3.询问安装cpu模式或gpu模式的docker
#4.输入volume本地地址
#5.安装docker，gpu需要安装nvidia-docker
#6.编译.../pyspider/Dockerfile或.../pyspider/Dockerfile
#7.启动镜像，并加载volume

# 注意：
# 1.dockerfile中注明EXPOSE 8000端口号。
# 
echo "# 测试步骤：执行完脚本需要在新命令行执行的命令"


IMAGENAME=pyspider_dockerimage
IMAGETAGCPU=py27_cpu
IMAGETAGGPU=py27_gpu

HOSTPORT_1=5000
HOSTPORT_2=23333 
HOSTPORT_3=24444 
HOSTPORT_4=25555
OUTPORT_1=5000 
OUTPORT_2=23333 
OUTPORT_3=24444 
OUTPORT_4=25555




echo "####################################################"
echo "##						##"
echo "##	询问安装cpu模式或gpu模式的docker		##"
echo "##						##"
echo "####################################################"
FLAG=0
CHIPMODE="cpu"
#FLAG=1
#CHIPMODE=""
while [ $FLAG -eq 1 ] 
do
	echo -n "Enter your workspace mode (cpu|gpu):"
	read mode
	if
	[ "$mode"x = "cpu"x -o "$mode"x = "gpu"x ];
	then
 	     	CHIPMODE=$mode
		echo "Set Workspace mode to $mode."
		echo "You will use $mode for Docker's Installation and Dockerfile's Buiding and so on."
		FLAG=0
	else
	     	FLAG=1
	fi
done
echo


echo "####################################################"
echo "##						##"
echo "##	输入volume本地地址连接到docker		##"
echo "##						##"
echo "####################################################"
#FLAGVOL=0
FLAGVOL=1
while [ $FLAGVOL -eq 1 ] 
do
	echo "Please input volume's path."
	echo "For Example:/home/$USER/PythonProjects/pyspider/pyspider_workspace/pyspider "
	echo -n "The Volume Path is:"
	read VOLUMEPATH
	if [ ! -d "$VOLUMEPATH" ]; then
		
 		echo "There is no Path called '$VOLUMEPATH'."
		FLAGVOL=1
	else
		if [[ "$VOLUMEPATH" =~ /$ ]]; 
		then
			echo "There should be no '/' at the end of Path '$VOLUMEPATH'."
			FLAGVOL=1
		else
			echo -n "Comfirm the path (yes|no):"
			read cf
			if [ "$cf"x = "yes"x ];
			then
				FLAGVOL=0
			else
		    		FLAGVOL=1
			fi

		fi
		
	fi
done

echo "####################################################################"
echo "##								##"
echo "##	检测docker是否安装，gpu模式检测nvidia-docker是否安装	##"
echo "##								##"
echo "####################################################################"
# 检验docker是否安装，如果是gpu模式则检验nvidia-docker 
# FLAGDK==1 docker已安装，==0 docker未安装
FLAGDK=1
sudo docker run hello-world >/dev/null 2>&1
if [ $? -eq 0 ];
then
	echo "Docker ($CHIPMODE mode) has been Installed."
	FLAGDK=1
else
	echo "Docker ($CHIPMODE mode) has been not Installed."
	FLAGDK=0
fi 

# FLAGNVDK==1 nvidia-docker已安装，==0 nvidia-docker未安装
FLAGNVDK=1
if [ "$CHIPMODE"x = "gpu"x ];
then
	sudo nvidia-docker run --rm nvidia/cuda nvidia-smi
	if [ $? -eq 0 ];
	then
		echo "nvidia-docker ($CHIPMODE mode) has been Installed."
		FLAGNVDK=1
	else
		echo "nvidia-docker ($CHIPMODE mode) has been not Installed."
		FLAGNVDK=0
	fi 
fi






echo "####################################################################"
echo "##								##"
echo "##	安装docker，gpu模式还需要安装nvidia-docker		##"
echo "##								##"
echo "####################################################################"
## cpu
if [ $FLAGDK -eq 0 ];
then
	# step 1: 安装必要的一些系统工具
	sudo apt-get remove docker docker-engine docker-ce docker.io
	apt-get update
	apt-get upgrade
	sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
	# step 2: 安装GPG证书
	curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
	# Step 3: 写入软件源信息
	sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
	# Step 4: 更新并安装 Docker-CE
	sudo apt-get -y update
	sudo apt-get -y install docker-ce
	#建立 docker 组：
	sudo groupadd docker
	#将当前用户加入 docker 组：
	sudo gpasswd -a ${USER} docker
	if [ $? -eq 0 ];
	then
		echo "Docker is Installed!"
	fi
else
	echo "Docker is Installed!"
fi


echo

echo "####################################################################"
echo "##								##"
echo "##		gpu需要安装nvidia-docker			##"
echo "##								##"
echo "####################################################################"
# 装显卡驱动？装CUDNN？
## gpu
if [ "$CHIPMODE"x = "gpu"x ];
then
	# If you have nvidia-docker 1.0 installed: we need to remove it and all existing GPU containers
	docker volume ls -q -f driver=nvidia-docker | xargs -r -I{} -n1 docker ps -q -a -f volume={} | xargs -r docker rm -f
	sudo apt-get purge -y nvidia-docker

	# Add the package repositories
	curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | \
	  sudo apt-key add -
	distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
	curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
	  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
	sudo apt-get update

	# Install nvidia-docker2 and reload the Docker daemon configuration
	sudo apt-get install -y nvidia-docker2
	sudo pkill -SIGHUP dockerd

	# Test nvidia-smi with the latest official CUDA image
	docker run --runtime=nvidia --rm nvidia/cuda nvidia-smi

	if [ $? -eq 0 ];
	then
		echo "Nvidia-Docker is Installed."
	fi
else
	echo "Nvidia-Docker is Installed."
fi

echo
echo "############################################################################"
echo "##									##"
echo "##	检测是否有pyspider_DockerImage:py27_cpu或pyspider_DockerImage:py27_gpu镜像	##"
echo "##	编译.../pyspider/Dockerfile		##"
echo "##	或.../pyspider/Dockerfile		##"
echo "##									##"
echo "############################################################################"

# docker提速
#sudo docker --registry-mirror=https://registry.docker-cn.com daemon
if [ "$CHIPMODE"x = "cpu"x ];
then
	imagetagname=sudo docker images | awk  '$1=="$IMAGENAME"{print  $1":"$2}' | grep "$IMAGENAME:$IMAGETAGCPU"
	echo $imagetagname
	if [ "$imagetagname"x != "$IMAGENAME:$IMAGETAGCPU"x  ];
	then
		sudo docker build -t $IMAGENAME:$IMAGETAGCPU -f ${VOLUMEPATH}/Dockerfile ${VOLUMEPATH}
	else 
		echo " dockerfile for cpu is aready installed!"
	fi
fi

if [ "$CHIPMODE"x = "gpu"x ];
then
	imagetagname=sudo docker images | awk  '$1=="$IMAGENAME"{print  $1":"$2}' | grep "$IMAGENAME:$IMAGETAGGPU"
	if [ "$imagetagname"x != "$IMAGENAME:$IMAGETAGGPU"x  ];
	then
		sudo docker build -t $IMAGENAME:$IMAGETAGGPU -f ${VOLUMEPATH}/Dockerfile ${VOLUMEPATH}
	else 
		echo " dockerfile for gpu is aready installed!"
	
	fi
fi



#描述：删除顽固的None镜像

##sudo docker ps -a | grep "Exited" | awk '{print $1 }'|xargs docker stop 
##sudo docker ps -a | grep "Exited" | awk '{print $1 }'|xargs docker rm
##sudo docker images|grep none|awk '{print $3 }'|xargs -r docker rmi


echo
echo "############################################################################"
echo "##									##"
echo "##	显示镜像IP，端口号，镜像名，数据地址，各种命令			##"
echo "##									##"
echo "############################################################################"

if [ "$CHIPMODE"x = "cpu"x ];
then
	echo "镜像名称:$IMAGENAME:$IMAGETAGCPU"
fi
if [ "$CHIPMODE"x = "gpu"x ];
then
	echo "镜像名称: $IMAGENAME:$IMAGETAGGPU"
fi
local_host="`hostname --fqdn`"
local_ip=`host $local_host 2>/dev/null | awk '{print $NF}'`
echo "主机IP:  $local_ip"
echo "主机端口号:$HOSTPORT，对外端口号:$OUTPORT"
echo "# 测试步骤：执行完脚本需要在新命令行执行的命令"
echo "# 1.cd pyspider/"




echo
echo "############################################"
echo "##	运行，start镜像，并加载volume	##"
echo "############################################"
# Run the app, mapping your machine’s $HOSTPORT to the container’s published port $OUTPORT using -p:
if [ "$CHIPMODE"x = "cpu"x ];
then
	# mysql
	#sudo docker stop mysql
	#sudo docker rm mysql
	#sudo docker run --name mysql -d -v /data/mysql:/var/lib/mysql -e MYSQL_ALLOW_EMPTY_PASSWORD=yes mysql:latest
	# rabbitmq
	#sudo docker stop rabbitmq
	#sudo docker rm rabbitmq
	#sudo docker run --name rabbitmq -d rabbitmq:latest

	# phantomjs
	#sudo docker run --name phantomjs -d binux/pyspider:latest phantomjs

	# result worker
	#sudo docker run --name result_worker -m 128m -d --link mysql:mysql --link rabbitmq:rabbitmq binux/pyspider:latest result_worker
	# processor, run multiple instance if needed.
	#sudo docker run --name processor -m 256m -d --link mysql:mysql --link rabbitmq:rabbitmq binux/pyspider:latest processor
	# fetcher, run multiple instance if needed.
	#sudo docker run --name fetcher -m 256m -d --link phantomjs:phantomjs --link rabbitmq:rabbitmq binux/pyspider:latest fetcher --no-xmlrpc
	# scheduler
	#sudo docker run --name scheduler -d --link mysql:mysql --link rabbitmq:rabbitmq binux/pyspider:latest scheduler
	# webui
	#sudo docker run --name webui -m 256m -d -p 5000:5000 --link mysql:mysql --link rabbitmq:rabbitmq --link phantomjs:phantomjs binux/pyspider:latest webui

	#sudo docker run --name webui -m 256m -d -p 5000:5000 --link mysql:mysql --link rabbitmq:rabbitmq --link scheduler:scheduler --link phantomjs:phantomjs binux/pyspider:latest webui

	#sudo docker run --name webui -m 256m -d -p $HOSTPORT_1:$OUTPORT_1  -it --link mysql:mysql --link rabbitmq:rabbitmq  $IMAGENAME:$IMAGETAGCPU 
	sudo docker run -it -p $HOSTPORT_1:$OUTPORT_1   $IMAGENAME:$IMAGETAGCPU 
	echo
fi


