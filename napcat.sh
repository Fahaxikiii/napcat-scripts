#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CURRENT_DIR=$(
    cd "$(dirname "$0")" || exit
    pwd
)

echo -e '\033[35m'

cat << EOF
 ███╗   ██╗ █████╗ ██████╗  ██████╗ █████╗ ████████╗
 ████╗  ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗╚══██╔══╝
 ██╔██╗ ██║███████║██████╔╝██║     ███████║   ██║   
 ██║╚██╗██║██╔══██║██╔═══╝ ██║     ██╔══██║   ██║   
 ██║ ╚████║██║  ██║██║     ╚██████╗██║  ██║   ██║   
 ╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝      ╚═════╝╚═╝  ╚═╝   ╚═╝   
EOF

echo -e '\033[0m'

echo "当前目录为 $CURRENT_DIR"

function log() {
    message="[Napcat Log]: $1 "

    case "$1" in
        *"失败"*|*"错误"*|*"请使用 root 或 sudo 权限运行此脚本"*|*"暂不支持的系统架构，请参阅官方文档，选择受支持的系统。"*)
            echo -e "${RED}${message}${NC}" 2>&1 | tee -a "${CURRENT_DIR}"/install.log
            ;;
        *"成功"*)
            echo -e "${GREEN}${message}${NC}" 2>&1 | tee -a "${CURRENT_DIR}"/install.log
            ;;
        *"忽略"*|*"跳过"*)
            echo -e "${YELLOW}${message}${NC}" 2>&1 | tee -a "${CURRENT_DIR}"/install.log
            ;;
        *)
            echo -e "${BLUE}${message}${NC}" 2>&1 | tee -a "${CURRENT_DIR}"/install.log
            ;;
    esac
}

function Check_System() {
    osCheck=$(uname -m)

    if [[ $osCheck != "x86_64" && $osCheck != "amd64" ]]; then
        log "暂不支持的系统架构，请参阅官方文档，选择受支持的系统。"
        exit 1
    fi

    if ! command -v apt &> /dev/null; then
        log "未检测到 apt 包管理器，请参阅官方文档，选择受支持的系统。"
        exit 1
    fi
}

function Check_Root() {
    if [[ $EUID -ne 0 ]]; then
        log "请使用 root 或 sudo 权限运行此脚本"
        exit 1
    fi
}

function Docker_Network_Test() {
    docker_target_proxy=""
    docker_proxy_arr=("docker.1panel.dev" "dockerpull.com" "docker.rainbond.cc" "dockerproxy.cn" "docker.agsvpt.work" "docker.agsv.top" "docker.registry.cyou")

    for docker_proxy in "${docker_proxy_arr[@]}"; do
        docker_status=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$docker_proxy/")

        if [ $docker_status -eq 200 ] || [ $docker_status -eq 301 ]; then
            docker_target_proxy="$docker_proxy"
            log "将使用Docker代理: $docker_proxy"
            break
        else
            log "无可用代理, 将直接连接Docker..."
        fi

    done
}

function Github_Network_Test() {
    github_target_proxy=""
    github_proxy_arr=( "https://ghp.ci" "https://github.moeyy.xyz" "https://mirror.ghproxy.com" "https://gh-proxy.com" "https://x.haod.me")

    for github_proxy in "${github_proxy_arr[@]}"; do
        github_status=$(curl -o /dev/null -s -w "%{http_code}" --max-time 10 "$github_proxy/")

        if [ $github_status -eq 200 ]; then
            github_target_proxy="$github_proxy"
            log "将使用Github代理: $github_proxy"
            break
        else
            log "无可用代理, 将直接连接Github..."
        fi

    done
}

function Change_Repo() {
    log "nothing"
}

function Install_Fonts() {
    apt install fonts-wqy-zenhei fonts-wqy-microhei -y > /dev/null 2>&1 &
    fc-cache -fv > /dev/null 2>&1 &
    log "中文字体安装完成，若不生效请重启服务器"
}

function Check_Docker() {
    while true; do

        if command -v docker >/dev/null 2>&1; then
            docker_version=$(docker --version | awk '{print $3}' | sed 's/,//g')
        #   docker_major=$(echo "$docker_version" | cut -d. -f1)
            log "检测到 Docker 已安装，当前版本为 $docker_version"

        #   if [ "$docker_major" -ge 27 ]; then
        #       log "Docker 版本大于或等于 27, 跳过安装步骤"

                    if systemctl is-active --quiet docker; then
                        log "Docker 已在运行, 不需要重启"
                        break
                    else
                        log "启动 Docker"
                        systemctl start docker 2>&1 | tee -a "${CURRENT_DIR}"/install.log
                        break
                    fi

            #   break
            # else
            #     log "Docker 版本小于 27, 执行安装更新步骤"
            #     Install_Docker
            #     break
            # fi

        else
            log "未检测到 Docker, 正在安装"
            Install_Docker
            break
        fi

    done
}

function Install_Docker() {
    while true; do

        log "请选择 Docker 安装方式："
        log "1. 在线安装"
        log "2. 离线安装"
        read -p "请输入选择 (回车默认在线安装): " choiceway
        choiceway=${choiceway:-1}
        
        if [ "$choiceway" = "1" ]; then
            log "... 在线安装 Docker"
            # curl -fsSL https://get.docker.com -o get-docker.sh
            # curl -fsSL https://nclatest.znin.net/docker_install_script -o get-docker.sh
            curl -fsSL https://wanli.icu/get-docker.sh -o get-docker.sh
            chmod +x get-docker.sh
            sh get-docker.sh
        elif [ "$choiceway" = "2" ]; then
            log "... 离线安装 Docker"
            Github_Network_Test
            curl -O ${github_target_proxy:+${github_target_proxy}/}https://github.com/Fahaxikiii/myscripts/releases/download/docker/docker.tar.gz
            tar zxvf docker.tar.gz
            chmod +x docker/bin/*
            cp docker/bin/* /usr/bin/
            cp docker/service/docker.service /etc/systemd/system/
            chmod 754 /etc/systemd/system/docker.service
            mkdir -p /etc/docker/
            cp docker/conf/daemon.json /etc/docker/daemon.json
            log "... 启动 docker"
            systemctl enable docker; systemctl daemon-reload; systemctl start docker 2>&1 | tee -a "${CURRENT_DIR}"/install.log
        # if command -v docker >/dev/null 2>&1; then
        #     docker_new_version=$(docker --version | awk '{print $3}' | sed 's/,//g')
        #     log "Docker 已安装，版本为 $docker_new_version"
#             if [ ! -f /etc/docker/daemon.json ]; then
#                 touch /etc/docker/daemon.json
#             fi

# cat <<EOF > /etc/docker/daemon.json
# {
#     "registry-mirrors": [
#         "https://docker.rainbond.cc"
#     ]
# }
# EOF
#             log "... 重载 docker"
#             systemctl enable docker
#             systemctl daemon-reload
#             systemctl restart docker 2>&1 | tee -a "${CURRENT_DIR}"/install.log
            # break 
        else
            log "无效的选择，请重新输入"
            continue
        fi

        if command -v docker >/dev/null 2>&1; then
            docker_new_version=$(docker --version | awk '{print $3}' | sed 's/,//g')
            log "Docker 已安装，版本为 $docker_new_version"
            break
        else
            log "Docker 安装更新失败"
            read -p "是否重试安装 Docker? 请尝试另一种方法(Y/n): " retry

            if [ "$retry" = "Y" ] || [ "$retry" = "y" ] || [ -z "$retry" ]; then
                log "重试安装 Docker..."
                continue
            else
                log "退出安装"
                exit 1
            fi

        fi

    done
}

function Check_Docker-Compose() {
    if command -v docker-compose >/dev/null 2>&1; then
        log "检测到 docker-compose 已安装, 跳过安装步骤"
    else
        apt install docker-compose
    fi
}

function Set_Container_Name() {
    DEFAULT_CONTAINER_NAME="napcat"

    while true; do
        read -p "设置容器名称(默认为$DEFAULT_CONTAINER_NAME): " CONTAINER_NAME

        if [[ "$CONTAINER_NAME" == "" ]];then
            CONTAINER_NAME=$DEFAULT_CONTAINER_NAME
        fi

        log "您设置的容器名称为: $CONTAINER_NAME"
        break
    done
}

function Set_QQ_Account() {
    DEFAULT_QQ_ACCOUNT="123456789"

    while true; do
        read -p "设置 机器人QQ号(默认为$DEFAULT_QQ_ACCOUNT): " QQ_ACCOUNT

        if [[ "$QQ_ACCOUNT" == "" ]];then
            QQ_ACCOUNT=$DEFAULT_QQ_ACCOUNT
        fi
        
        if [[ ! "$QQ_ACCOUNT" =~ ^[0-9]{1,30}$ ]]; then
            log "错误: QQ号仅支持数字,长度 1-30 位"
            continue
        fi

        log "您设置的机器人QQ号为: $QQ_ACCOUNT"
        break
    done
}

function Set_Config_Path() {
    while true; do
        log "当前目录为 $CURRENT_DIR"
        if read -t 120 -p "设置 NAPCAT 安装目录(默认为/root/napcat): " CONFIG_PATH; then

            if [[ "$CONFIG_PATH" != "" ]]; then

                if [[ "$CONFIG_PATH" != /* ]]; then
                    log "请输入目录的完整路径"
                    continue
                fi

                if [[ ! -d $CONFIG_PATH ]]; then
                    mkdir -p "$CONFIG_PATH"
                    mkdir -p "$CONFIG_PATH/QQ"
                    mkdir -p "$CONFIG_PATH/config"
                    mkdir -p "$CONFIG_PATH/logs"
                    log "您设置的安装路径为: $CONFIG_PATH"
                    log "您设置的QQ持久化数据路径为: $CONFIG_PATH/QQ"
                    log "您设置的NapCat配置文件路径为: $CONFIG_PATH/config"
                    log "您设置的NapCat日志输出路径为: $CONFIG_PATH/logs"
                    break
                fi

            else
                CONFIG_PATH=/root/napcat
                mkdir -p "$CONFIG_PATH"
                mkdir -p "$CONFIG_PATH/QQ"
                mkdir -p "$CONFIG_PATH/config"
                mkdir -p "$CONFIG_PATH/logs"
                log "您设置的安装路径为: $CONFIG_PATH"
                log "您设置的QQ持久化数据路径为: $CONFIG_PATH/QQ"
                log "您设置的NapCat配置文件路径为: $CONFIG_PATH/config"
                log "您设置的NapCat日志输出路径为: $CONFIG_PATH/logs"
                break
            fi

        else
            CONFIG_PATH=/root/napcat
            mkdir -p "$CONFIG_PATH"
            mkdir -p "$CONFIG_PATH/QQ"
            mkdir -p "$CONFIG_PATH/config"
            mkdir -p "$CONFIG_PATH/logs"
            log "(设置超时，使用默认安装路径 /root/napcat)"
            log "您设置的QQ持久化数据路径为: $CONFIG_PATH/QQ"
            log "您设置的NapCat配置文件路径为: $CONFIG_PATH/config"
            log "您设置的NapCat日志输出路径为: $CONFIG_PATH/logs"
            break
        fi

    done
}

function Set_Bot_Path() {
    while true; do
        read -p "是否添加机器人目录(方便ffmpeg转码及发送本地文件) (Y/n): " addbot

        if [ "$addbot" = "Y" ] || [ "$addbot" = "y" ] || [ -z "$addbot" ]; then
            Add_Bot_Path
            break
        else
            log "跳过添加，继续下一步"
            break
        fi

    done
}

function Add_Bot_Path() {
    while true; do
        log "回车也可跳过添加，继续下一步"
        read -p "请输入机器人安装目录(如/root/zhenxun_bot): " BOT_PATH

        if [[ "$BOT_PATH" == "" ]]; then
            log "目录为空，跳过添加，继续下一步。"
            BOT_PATH=$BOT_PATH
            break
        elif [[ "$BOT_PATH" != /* ]]; then
            log "请输入目录的完整路径"
            continue
        elif [[ ! -d $BOT_PATH ]]; then
            log "目录不存在，请重新添加"
            continue
        fi

        BOT_PATH=$BOT_PATH
        break
    done
}

function Set_Webui_Host() {
    DEFAULT_WEBUI_HOST="0.0.0.0"

    while true; do
        read -p "设置WEBUI主机(默认为$DEFAULT_WEBUI_HOST): " WEBUI_HOST

        if [[ "$WEBUI_HOST" == "" ]];then
            WEBUI_HOST=$DEFAULT_WEBUI_HOST
        fi

        if [[ "$WEBUI_HOST" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            WEBUI_HOST=$WEBUI_HOST
            log "您设置的WEBUI主机为: $WEBUI_HOST"
            break
        elif [[ "$WEBUI_HOST" =~ ^\[?([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}\]?$ || "$WEBUI_HOST" == "::" ]]; then
            WEBUI_HOST=[$WEBUI_HOST]
            log "您设置的WEBUI主机为: $WEBUI_HOST"
            break
        else
            log "错误: 输入的主机必须是ipv4或ipv6地址"
            continue
        fi

        log "您设置的WEBUI主机为: $WEBUI_HOST"
        break
    done
}

function Set_Webui_Port() {
    DEFAULT_WEBUI_PORT="6099"

    while true; do
        read -p "设置 WEBUI 端口(默认为$DEFAULT_WEBUI_PORT): " WEBUI_PORT

        if [[ "$WEBUI_PORT" == "" ]];then
            WEBUI_PORT=$DEFAULT_WEBUI_PORT
        fi

        if ! [[ "$WEBUI_PORT" =~ ^[1-9][0-9]{0,4}$ && "$WEBUI_PORT" -le 65535 ]]; then
            log "错误: 输入的端口号必须在 1 到 65535 之间"
            continue
        fi

        if command -v ss >/dev/null 2>&1; then

            if ss -tlun | grep -q ":$WEBUI_PORT " >/dev/null 2>&1; then
                log "端口$WEBUI_PORT被占用, 请重新输入..."
                continue
            fi

        elif command -v netstat >/dev/null 2>&1; then

            if netstat -tlun | grep -q ":$WEBUI_PORT " >/dev/null 2>&1; then
                log "端口$WEBUI_PORT被占用, 请重新输入..."
                continue
            fi

        fi

        log "您设置的WEBUI端口为: $WEBUI_PORT"
        break
    done
}

function Set_Webui_Token() {
    DEFAULT_WEBUI_TOKEN="napcat"

    while true; do
        read -p "设置WEBUI密钥(默认为$DEFAULT_WEBUI_TOKEN): " WEBUI_TOKEN

        if [[ "$WEBUI_TOKEN" == "" ]];then
            WEBUI_TOKEN=$DEFAULT_WEBUI_TOKEN
        fi

        log "您设置的WEBUI密钥为: $WEBUI_TOKEN"
        break
    done
}

function Set_Webui_Login_Rate() {
    DEFAULT_WEBUI_LOGIN_RATE="3"

    while true; do
        read -p "设置WEBUI登录次数(默认为$DEFAULT_WEBUI_LOGIN_RATE): " WEBUI_LOGIN_RATE

        if [[ "$WEBUI_LOGIN_RATE" == "" ]];then
            WEBUI_LOGIN_RATE=$DEFAULT_WEBUI_LOGIN_RATE
        fi

        if [[ ! "$WEBUI_LOGIN_RATE" =~ ^[0-9]{1,30}$ ]]; then
            log "错误: WEBUI登录次数仅支持数字,长度 1-30 位"
            continue
        fi

        log "您设置的WEBUI登录次数为: $WEBUI_LOGIN_RATE"
        break
    done
}

function Create_Webui_Config() {
    WEBUI_PATH="$CONFIG_PATH/config/webui.json"

    touch "$WEBUI_PATH"
cat <<EOF > "$WEBUI_PATH"
{
    "host": "$WEBUI_HOST",
    "port": $WEBUI_PORT,
    "prefix": "",
    "token": "$WEBUI_TOKEN",
    "loginRate": $WEBUI_LOGIN_RATE
}
EOF
}

function Set_Mac_Address() {
    DEFAULT_MAC_ADDRESS=$(ip addr show $(ip route | awk '/default/ {print $5}') | grep link/ether | awk '{print $2}')

    while true; do
        read -p "设置 MAC_ADDRESS(默认为$DEFAULT_MAC_ADDRESS): " MAC_ADDRESS

        if [[ "$MAC_ADDRESS" == "" ]];then
            MAC_ADDRESS=$DEFAULT_MAC_ADDRESS
        fi

        if [[ ! "$MAC_ADDRESS" =~ ^([0-9a-fA-F]{2}(:|-)){5}[0-9a-fA-F]{2}$ ]]; then
            log "错误: MAC_ADDRESS格式错误"
            continue
        fi

        log "您设置的MAC_ADDRESS为: $MAC_ADDRESS"
        break
    done
}

function Set_Napcat_UID() {
    DEFAULT_NAPCAT_UID="0"

    while true; do
        read -p "设置Napcat UID(默认为$DEFAULT_NAPCAT_UID): " NAPCAT_UID

        if [[ "$NAPCAT_UID" == "" ]];then
            NAPCAT_UID=$DEFAULT_NAPCAT_UID
        fi

        if [[ ! "$NAPCAT_UID" =~ ^[0-9]{1,30}$ ]]; then
            log "错误: Napcat UID仅支持数字,长度 1-30 位"
            continue
        fi

        log "您设置的Napcat UID为: $NAPCAT_UID"
        break
    done
}

function Set_Napcat_GID() {
    DEFAULT_NAPCAT_GID="0"

    while true; do
        read -p "设置Napcat GID(默认为$DEFAULT_NAPCAT_GID): " NAPCAT_GID

        if [[ "$NAPCAT_GID" == "" ]];then
            NAPCAT_GID=$DEFAULT_NAPCAT_GID
        fi

        if [[ ! "$NAPCAT_GID" =~ ^[0-9]{1,30}$ ]]; then
            log "错误: Napcat GID仅支持数字,长度 1-30 位"
            continue
        fi

        log "您设置的Napcat GID为: $NAPCAT_GID"
        break
    done
}

function Get_Ip() {
    #active_interface=$(ip route get 8.8.8.8 | awk 'NR==1 {print $5}')
    active_interface=$(ip route | awk '/default/ {print $5}')
    PUBLIC_IPV4=$(curl -s 4.ipw.cn)
    PUBLIC_IPV6=$(curl -s 6.ipw.cn)

    if [[ -z $active_interface ]]; then
        LOCAL_IP="127.0.0.1"
    else
        LOCAL_IP=$(ip -4 addr show dev "$active_interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    fi

    if [[ -z "$PUBLIC_IPV4" ]]; then
        PUBLIC_IPV4="N/A"
    fi

    if echo "$PUBLIC_IPV4" | grep -q ":"; then
        PUBLIC_IPV4=${PUBLIC_IPV4}
    fi

    if [[ -z "$PUBLIC_IPV6" ]]; then
        PUBLIC_IPV6="N/A"
    fi

    if echo "$PUBLIC_IPV6" | grep -q ":"; then
        PUBLIC_IPV6=[${PUBLIC_IPV6}]
    fi
}

function Confirm_Napcat() {
    log "(1)您设置的容器名称为: $CONTAINER_NAME"
    log "(2)您设置的机器人QQ号为: $QQ_ACCOUNT"
    log "(3)您设置的QQ持久化数据路径为: $CONFIG_PATH/QQ"
    log "(3)您设置的NapCat配置文件路径为: $CONFIG_PATH/config"
    log "(3)您设置的NapCat日志输出路径为: $CONFIG_PATH/logs"
    log "(4)您设置的WEBUI主机为: $WEBUI_HOST"
    log "(5)您设置的WEBUI端口为: $WEBUI_PORT"
    log "(6)您设置的WEBUI密钥为: $WEBUI_TOKEN"
    log "(7)您设置的WEBUI登录次数为: $WEBUI_LOGIN_RATE"
    log "(8)您设置的MAC_ADDRESS为: $MAC_ADDRESS"
    log "(9)您设置的Napcat UID为: $NAPCAT_UID"
    log "(10)您设置的Napcat GID为: $NAPCAT_GID"

    if [[ "$BOT_PATH" != "" ]]; then
        log "(11)您设置的机器人目录为: $BOT_PATH"
    else
        log "(11)您设置的机器人目录为空"
    fi

    while true; do
        log "您想要继续修改数据还是继续下一步？直接回车进行安装"
        read -p "请输入数字选择您需要修改的数据:" choice

        case "$choice" in
            1)
                Set_Container_Name
                continue
                ;;
            2)
                Set_QQ_Account
                continue
                ;;
            3)
                Set_Config_Path
                continue
                ;;
            4)
                Set_Webui_Host
                continue
                ;;
            5)
                Set_Webui_Port
                continue
                ;;
            6)
                Set_Webui_Token
                continue
                ;;
            7)
                Set_Webui_Login_Rate
                continue
                ;;
            8)
                Set_Mac_Address
                continue
                ;;
            9)
                Set_Napcat_UID
                continue
                ;;
            10)
                Set_Napcat_GID
                continue
                ;;
            11)
                Set_Bot_Path
                continue
                ;;
            "")
                break
                ;;
            *)
                log "错误的选项，请重新输入。"
                continue
                ;;
        esac

    done
    log "开始安装，请您耐心等待。"
    Create_Napcat
}

function Create_Napcat() {
    Docker_Network_Test

    if [[ -n "$BOT_PATH" ]]; then

cat <<EOF > docker-compose.yml
services:
    ${CONTAINER_NAME}:
        container_name: ${CONTAINER_NAME}
        restart: always
        network_mode: "host"
        mac_address: "${MAC_ADDRESS}"
        environment:
            - "TZ=Asia/Shanghai"
            - "NAPCAT_UID=${NAPCAT_UID}"
            - "NAPCAT_GID=${NAPCAT_GID}"
            - "ACCOUNT=${QQ_ACCOUNT}"
        volumes:
            - "${CONFIG_PATH}/QQ:/app/.config/QQ"
            - "${CONFIG_PATH}/config:/app/napcat/config"
            - "${CONFIG_PATH}/logs:/app/napcat/logs"
            - "${BOT_PATH}":"${BOT_PATH}"
        image: ${docker_target_proxy:+${docker_target_proxy}/}mlikiowa/napcat-docker:latest
EOF

    else

cat <<EOF > docker-compose.yml
services:
    ${CONTAINER_NAME}:
        container_name: ${CONTAINER_NAME}
        restart: always
        network_mode: "host"
        mac_address: "${MAC_ADDRESS}"
        environment:
            - "TZ=Asia/Shanghai"
            - "NAPCAT_UID=${NAPCAT_UID}"
            - "NAPCAT_GID=${NAPCAT_GID}"
            - "ACCOUNT=${QQ_ACCOUNT}"
        volumes:
            - "${CONFIG_PATH}/QQ:/app/.config/QQ"
            - "${CONFIG_PATH}/config:/app/napcat/config"
            - "${CONFIG_PATH}/logs:/app/napcat/logs"
        image: ${docker_target_proxy:+${docker_target_proxy}/}mlikiowa/napcat-docker:latest
EOF

    fi
    
    # cp -f docker-compose.yml $CONFIG_PATH/docker-compose.yml
    # docker_run_cmd=(
    #     docker run -d \
    #         --name "$CONTAINER_NAME" \
    #         --restart always \
    #         --network host \
    #         --mac-address "$MAC_ADDRESS" \
    #         -e TZ=Asia/Shanghai \
    #         -e NAPCAT_UID="$NAPCAT_UID" \
    #         -e NAPCAT_GID="$NAPCAT_GID" \
    #         -e ACCOUNT="$QQ_ACCOUNT" \
    #         -v "$CONFIG_PATH/QQ":/app/.config/QQ \
    #         -v "$CONFIG_PATH/config":/app/napcat/config \
    #         -v "$CONFIG_PATH/logs":/app/napcat/logs
    # )

    # if [[ -n "$BOT_PATH" ]]; then
    #     docker_run_cmd+=(-v "$BOT_PATH":"$BOT_PATH")
    # fi

    # "${docker_run_cmd[@]}" ${docker_target_proxy:+${docker_target_proxy}/}mlikiowa/napcat-docker:latest
    # Show_Result
    Install_Napcat
}

function Check_Docker-Compose() {
    while true; do

    if [ -f "docker-compose.yml" ]; then
        break
    else
        log "docker-compose.yml文件不存在, 操作失败"
        exit 1
    fi

    done
}

function Install_Napcat() {
    docker-compsoe up -d
    Show_Result
}

function Reinstall_Napcat() {
    docker-compsoe stop
    Confirm_Napcat
}

function Stop_Napcat() {
    docker-compsoe stop
    log "成功停止"
}

function Restart_Napcat() {
    docker-compsoe restart
    log "重启成功"
}

function Update_Napcat() {
    docker-compsoe stop
    docker-compsoe pull
    docker-compsoe up -d
    log "更新成功"
}

function Show_Result() {
    log ""
    log "=================感谢您的耐心等待，安装已经完成=================="
    log ""
    log "Napcat 容器已启动，容器名称: $CONTAINER_NAME"
    log ""
    log "请用浏览器访问WEBUI:"
    log "外网地址: http://$PUBLIC_IPV4:$WEBUI_PORT/webui"
    log "外网地址: http://$PUBLIC_IPV6:$WEBUI_PORT/webui"
    log "内网地址: http://127.0.0.1:$WEBUI_PORT/webui"
    log "内网地址: http://$LOCAL_IP:$WEBUI_PORT/webui"
    log "访问密钥: $WEBUI_TOKEN"
    log ""
    log "项目官网: https://napneko.github.io/zh-CN"
    log "项目文档: https://napneko.github.io/zh-CN/guide/getting-started"
    log "代码仓库: https://github.com/NapNeko/NapCatQQ"
    log ""
    log "如果使用的是云服务器，请至安全组开放 $WEBUI_PORT 端口"
    log ""
    log "更新容器请执行以下命令"
    log "cd $CURRENT_DIR && docker-compsoe stop && docker-compsoe pull && docker-compsoe up -d"
    log ""
    log "================================================================"
}

function Main() {
    Check_System
    Check_Root
    log "(1)安装NapCat"
    log "(2)升级NapCat"
    log "(3)重启NapCat"
    log "(4)停止NapCat"
    log "(5)重建NapCat(咕咕咕)"
    log "(6)退出脚本"
    while true; do
        read -p "请输入数字选择您需要进行的操作:" mainchoice

        case "$mainchoice" in
            1)
                Check_Docker
                Check_Docker-Compose
                Set_Container_Name
                Set_QQ_Account
                Set_Config_Path
                Set_Bot_Path
                Set_Webui_Host
                Set_Webui_Port
                Set_Webui_Token
                Set_Webui_Login_Rate
                Create_Webui_Config
                Set_Mac_Address
                Set_Napcat_UID
                Set_Napcat_GID
                Get_Ip
                Confirm_Napcat
                break
                ;;
            2)
                Check_Docker-Compose
                Update_Napcat
                break
                ;;
            3)  
                Check_Docker-Compose
                Restart_Napcat
                break
                ;;
            4)
                Check_Docker-Compose
                Stop_Napcat
                break
                ;;
            5)
                Reinstall_Napcat
                break
                ;;
            6)
                log "欢迎您的使用"
                break
                ;;
            *)
                log "错误的选项，请重新输入。"
                continue
                ;;
        esac

    done
}

Main