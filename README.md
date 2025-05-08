### ArgoSB一键无交互脚本：极简、轻便的体验。兼容各种主流VPS

#### 1、安装最新sing-box内核+最新Cloudflared-Argo内核，支持Argo临时/固定隧道

#### 2、Argo临时/固定隧道区别：服务器重启或者宕机恢复后，临时域名会重置，固定域名保持不变，仅此区别！

#### 3、目前仅输出VMESS协议节点：13个端口节点及对应的优选不死IP全覆盖（80系无TLS+443系开TLS，两个IPV6）

脚本如下，默认安装为Argo临时隧道（UUID、主协议vmess端口未设变量时，为随机生成）
```
bash <(wget -qO- https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh)
```
或者
```
bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh)
```
---------------------------------------------------------

### 相关快捷方式：

1、查看Argo的固定域名、固定域名的token、临时域名、当前节点信息：

```agsb``` 或者 原完整脚本

2、升级ArgoSB脚本：

```agsb up``` 或者 ```bash <(wget -qO- https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh) up```

3、卸载ArgoSB脚本：

```agsb del``` 或者 ```bash <(wget -qO- https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh) del```

----------------------------------------------------------

### 可自定义设置相关变量参数

#### 1、Argo临时隧道：
#### 脚本前必须要有端口(vmpt)、UUID密码(uuid)两个变量，每次重装后临时域名都不相同
```
uuid=你的uuid vmpt=vps可使用的端口 bash <(wget -qO- https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh)
```
#### 2、Argo固定隧道：
#### 脚本前必须要有端口(vmpt)、UUID密码(uuid)、固定域名(agn)、token(agk)四个变量，每次重装后输出节点信息不变
```
vmpt=VPS可使用的端口 agn=固定域名 agk=ey开头的token bash <(wget -qO- https://raw.githubusercontent.com/yonggekkk/argosb/main/argosb.sh)
```

#### 注：如果服务器支持任意端口，临时隧道端口变量(vmpt)可以不用设置，因为Argo节点用不到主协议vmess的端口

----------------------------------------------------------

#### 相关教程可参考[甬哥博客](https://ygkkk.blogspot.com/2025/04/clawcloud.html)，视频教程如下：

[Claw.cloud免费VPS搭建代理最终教程：全网最简单 | 两大无交互回车脚本 | 套CDN优选IP | workers反代 | ArgoSB隧道搭建](https://youtu.be/Esofirx8xrE)

[Google IDX VPS代理搭建教程（二）：ArgoSB一键代理脚本发布 | 一次回车搞定一切 | 懒人小白最强Argo代理节点脚本](https://youtu.be/OoXJ_jxoEyY)

更新中……

----------------------------------------------------------

### 交流平台：[甬哥博客地址](https://ygkkk.blogspot.com)、[甬哥YouTube频道](https://www.youtube.com/@ygkkk)、[甬哥TG电报群组](https://t.me/+jZHc6-A-1QQ5ZGVl)、[甬哥TG电报频道](https://t.me/+DkC9ZZUgEFQzMTZl)

----------------------------------------------------------
### 感谢支持！微信打赏甬哥侃侃侃ygkkk
![41440820a366deeb8109db5610313a1](https://github.com/user-attachments/assets/e5b1f2c0-bd2c-4b8f-8cda-034d3c8ef73f)

----------------------------------------------------------
### 感谢你右上角的star🌟
[![Stargazers over time](https://starchart.cc/yonggekkk/ArgoSB.svg)](https://starchart.cc/yonggekkk/ArgoSB)

----------------------------------------------------------

### Thanks to [VTEXS](https://console.vtexs.com/?affid=1558) for the sponsorship support

----------------------------------------------------------
