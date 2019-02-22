# 描述: 爬取指定页面自定义模板的信息,可保存在csv文件
# 运行步骤
1. 执行./pyspider_install_manager.sh
2. 浏览器打开 http://localhost:5000 


# pyspider_workspace
/home/leo/PythonProjects/pyspider/pyspider_workspace


#报错:
WARNING: Your kernel does not support swap limit capabilities, memory limited without swap.

解决办法：
1. sudo vim /etc/default/grub
2. 在grub文件末尾添加如下配置
GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"
3. 更新grub
sudo update-grub
4. 重启操作系统



