/**
 * @addtogroup module_DNCP
 * @{
 */

/**
 * @file
 * @brief 链路适配接口Windows串口的实现。
 * @details 实现Windows平台的串口通信Lai层实体。
 * @version 1.0.0
 * @author kim.xiejinqiang
 * @date 2013-1-15
 */

#include <stdio.h>
#include <pthread.h>
//#include <QThread>
//#include <QSerialPort>
//#include <QDebug>
//#include "Log.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>    // 串口配置
#include <sys/select.h> // 超时读
#include <pthread.h>
#include <sys/syscall.h> // gettid()
#include "hilog/log.h"
#include "LaiSerial.h"

//*******************************************************************

// 帧接收状态逻辑

// 帧解析状态定义
#define FPS_FRAME_TRY_SYNC      1   // 帧等待同步中（未同步上）
#define FPS_FRAME_RECEIVING     2   // 帧接收中（已同步上）

// 帧解析过程中的转义状态定义
#define RES_ESC_NORMAL          1   // 正常状态，无转义
#define RES_ESC_ACTION          2   // 转义中


//*******************************************************************
// LaiSerialThread 实现

// LaiSerial 通信线程，处理数据收发。
class LaiSerialThread
{
public:
    LaiSerialThread(LaiSerial* lai)
    {
        this->lai = lai;
    }

protected:
//    void run()
//    {
////        logger->debug("LaiSerial Thread ID = %d", QThread::currentThreadId());
//        OH_LOG_DEBUG(LOG_APP, "LaiTcpClient Thread ID = %{public}d", std::this_thread::get_id());
//        Byte buffer[FRAME_MAX_SIZE * 2];
//        Uint32 len;
//        bool isReadyRead;
//        Uint32 i;
//        Byte data;
//        Uint16 recvBytes;
//        Bool isFrameDetected = FALSE;
//        Byte* recvBuffer = lai->recvBuffer;
//        Bool isSending;
////        QSerialPort* serial;
//        int serial_fd;
//        
//        // 创建串口对象，打开串口并配置，有异常则退出线程
//        if (lai->serialPort)
//            delete lai->serialPort;
//        serial = new QSerialPort;
//        if (serial == nullptr)
//            return;
//        lai->serialPort = serial;
//
//        serial->setPortName(lai->portName);
//        if (serial->open(QIODevice::ReadWrite))
//        {
//            serial->setBaudRate(QSerialPort::Baud115200);
//            serial->setDataBits(QSerialPort::Data8);
//            serial->setParity(QSerialPort::NoParity);
//            serial->setStopBits(QSerialPort::OneStop);
//            serial->setFlowControl(QSerialPort::NoFlowControl);
//        }
//        else
//        {
//            if (lai->serialPort)
//            {
//                delete lai->serialPort;
//                lai->serialPort = nullptr;
//            }
//            printf("\n######### Error while open serial port %s.\n\n", lai->portName);
//            return;
//        }
//
//        while(lai->isCommunicatingThreadRunning)
//        {
//            // 需要及时退出接收等待（阻塞），以定期检查是否有数据包要发送
//            isReadyRead = serial->waitForReadyRead(5);
//
//            if (isReadyRead)        // 接收逻辑
//            {
//                // 接到一堆数据，解析中。。。
//                len = serial->read((char*)buffer, sizeof buffer);
//
//                // 超时无数据，跳过下面的逻辑
//                if (len == 0)
//                    continue;
//
//                // 使用局部变量，以提高效率，减少代码
//                recvBytes = lai->recvBytes;
//
//                for (i = 0; i < len; i++)
//                {
//                    data = buffer[i];
//
//
//                    // 帧同步状态机
//                    if (lai->recvStatus == FPS_FRAME_TRY_SYNC)
//                    {
//                        if (data == FRAME_CHAR_SYNC)
//                        {
//                            lai->recvStatus = FPS_FRAME_RECEIVING;
//                        }
//                        else
//                        {
//                            // 帧外数据统计
//                            (lai->base.commStat.outOfFrameBytes)++;
//                            printf("\n OOD: %02X", data);
//                        }
//                    }
//                    else
//                    {
//                        // FPS_FRAME_RECEIVING  帧接收中（已同步上）
//
//                        // 转义状态机
//                        if (lai->recvEscStatus == RES_ESC_ACTION)
//                        {
//                            if (data == FRAME_CHAR_RAW_SYNC)      // 原始字符为同步符
//                            {
//                                data = FRAME_CHAR_SYNC;
//                            }
//                            else if (data == FRAME_CHAR_RAW_ESC)  // 原始字符为转义符
//                            {
//                                data = FRAME_CHAR_ESC;
//                            }
//                            else
//                            {
//                                // 未定义的转义状态，通信可能出错，终结该帧
//                                data = FRAME_CHAR_SYNC;
//                                lai->recvStatus = FPS_FRAME_TRY_SYNC;
//
//                                // 认为解析到一帧
//                                isFrameDetected = TRUE;
//                            }
//
//                            recvBuffer[recvBytes++] = data;
//                            lai->recvEscStatus = RES_ESC_NORMAL;
//                        }
//                        else
//                        {
//                            // 未转义
//
//                            if (data == FRAME_CHAR_ESC)
//                            {
//                                lai->recvEscStatus = RES_ESC_ACTION;
//                            }
//                            else if (data == FRAME_CHAR_SYNC)
//                            {
//                                // 忽略空帧，防止帧同步符异常造成之后同步不上的问题
//                                if (recvBytes > 0)
//                                {
//                                    // 解析到一帧
//                                    isFrameDetected = TRUE;
//                                    lai->recvStatus = FPS_FRAME_TRY_SYNC;
//                                }
//                            }
//                            else
//                            {
//                                // 正常字符，提交
//                                recvBuffer[recvBytes++] = data;
//                            }
//                        }
//                    }
//
//                    // 检测到新的数据帧
//                    if (isFrameDetected)
//                    {
//                        ++(lai->base.commStat.recvFrames);
//
//                        // 拷贝到备用缓冲，防止数据被冲掉
//                        memcpy(lai->recvBackup, recvBuffer, recvBytes);
//                        lai->base.handle->OnReceived(lai->base.handle, lai->recvBackup, recvBytes, lai->sendTo);
//
//                        recvBytes = 0;
//                        isFrameDetected = FALSE;
//                    }
//                }
//
//                // 更新到对象
//                lai->recvBytes = recvBytes;
//            }
//            else        // 发送逻辑
//            {
//                //pthread_mutex_lock(&lai->mutexSending);
//                isSending = lai->isSending;
//                // pthread_mutex_unlock(&lai->mutexSending);   
//
//                if (isSending)
//                {
//                    //pthread_mutex_lock(&lai->mutexSending);
//                    serial->write((const char*)lai->sendBuffer, lai->sendBytes);
//                    serial->waitForBytesWritten(1000);
//                    pthread_mutex_lock(&lai->mutexSending);                    
//                    lai->isSending = FALSE;
//                     pthread_mutex_unlock(&lai->mutexSending);                      
//
//                    if (lai->base.handle->OnSendQuery(lai->base.handle) > 0)
//                    {
//                        lai->base.handle->OnSendRequest(lai->base.handle);
//                    }
//                }
//            }
//        }
//
//        if (lai->serialPort)
//        {
//            lai->serialPort->close();
//            delete lai->serialPort;
//            lai->serialPort = nullptr;
//        }
//    }

private:
    LaiSerial* lai;
};


//*******************************************************************
// Lai 实现

static void LaiSerial_Reset(LaiSerial* lai, Uint16 action);
static Bool LaiSerial_IsSendable(LaiSerial* lai);
static void LaiSerial_Send(LaiSerial* lai, Uint8 destAddr, Byte* data, int len);

static const ILaiComm s_kCommInterface =
{
        (IfLaiReset) LaiSerial_Reset,
        (IfLaiIsSendable) LaiSerial_IsSendable,
        (IfLaiSend) LaiSerial_Send
};

static int open_serial_port(const char* port_name) {
    int fd = open(port_name, O_RDWR | O_NOCTTY | O_NDELAY);
    if (fd == -1) {
        OH_LOG_ERROR(LOG_APP, "Failed to open serial port %{public}s: %{public}s", 
                     port_name, strerror(errno));
        return -1;
    }

    struct termios tty;
    if (tcgetattr(fd, &tty) != 0) {
        OH_LOG_ERROR(LOG_APP, "tcgetattr failed: %{public}s", strerror(errno));
        close(fd);
        return -1;
    }

    // 设置波特率（115200）
    cfsetospeed(&tty, B115200);
    cfsetispeed(&tty, B115200);

    // 数据位：8
    tty.c_cflag &= ~CSIZE;
    tty.c_cflag |= CS8;

    // 无校验
    tty.c_cflag &= ~PARENB;

    // 1 停止位
    tty.c_cflag &= ~CSTOPB;

    // 无流控
    tty.c_cflag &= ~CRTSCTS;

    // 原始模式
    tty.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
    tty.c_oflag &= ~OPOST;

    // 设置最小字符数和超时（非阻塞基础）
    tty.c_cc[VMIN] = 0;   // 非阻塞
    tty.c_cc[VTIME] = 0;

    // 应用配置
    if (tcsetattr(fd, TCSANOW, &tty) != 0) {
        OH_LOG_ERROR(LOG_APP, "tcsetattr failed: %{public}s", strerror(errno));
        close(fd);
        return -1;
    }

    // 清空缓冲区
    tcflush(fd, TCIOFLUSH);

    return fd;
}

// 线程入口函数
static void* LaiSerial_ThreadFunc(void* arg) {
    LaiSerial* lai = (LaiSerial*)arg;

    // 获取线程 ID（用于日志）
    pid_t tid = syscall(SYS_gettid);
    OH_LOG_DEBUG(LOG_APP, "LaiSerial Thread ID = %{public}d", (int)tid);

    // 打开串口
    lai->serial_fd = open_serial_port(lai->portName);
    if (lai->serial_fd == -1) {
        printf("\n######### Error while open serial port %s.\n\n", lai->portName);
        return nullptr;
    }

    Byte buffer[FRAME_MAX_SIZE * 2];
    Uint32 len;
    Bool isFrameDetected = FALSE;
    Byte* recvBuffer = lai->recvBuffer;
    Bool isSending;

    while (lai->isCommunicatingThreadRunning) {
        // 使用 select 实现 5ms 超时等待
        fd_set read_fds;
        FD_ZERO(&read_fds);
        FD_SET(lai->serial_fd, &read_fds);

        struct timeval timeout;
        timeout.tv_sec = 0;
        timeout.tv_usec = 5000; // 5ms

        int ready = select(lai->serial_fd + 1, &read_fds, NULL, NULL, &timeout);

        if (ready > 0 && FD_ISSET(lai->serial_fd, &read_fds)) {
            // 有数据可读
            ssize_t n = read(lai->serial_fd, buffer, sizeof(buffer));
            if (n <= 0) continue;

            len = (Uint32)n;
            Uint32 recvBytes = lai->recvBytes;

            // === 原有帧解析逻辑（完全保留）===
            for (Uint32 i = 0; i < len; i++) {
                Byte data = buffer[i];

                if (lai->recvStatus == FPS_FRAME_TRY_SYNC) {
                    if (data == FRAME_CHAR_SYNC) {
                        lai->recvStatus = FPS_FRAME_RECEIVING;
                    } else {
                        (lai->base.commStat.outOfFrameBytes)++;
                        printf("\n OOD: %02X", data);
                    }
                } else {
                    if (lai->recvEscStatus == RES_ESC_ACTION) {
                        if (data == FRAME_CHAR_RAW_SYNC) {
                            data = FRAME_CHAR_SYNC;
                        } else if (data == FRAME_CHAR_RAW_ESC) {
                            data = FRAME_CHAR_ESC;
                        } else {
                            data = FRAME_CHAR_SYNC;
                            lai->recvStatus = FPS_FRAME_TRY_SYNC;
                            isFrameDetected = TRUE;
                        }
                        recvBuffer[recvBytes++] = data;
                        lai->recvEscStatus = RES_ESC_NORMAL;
                    } else {
                        if (data == FRAME_CHAR_ESC) {
                            lai->recvEscStatus = RES_ESC_ACTION;
                        } else if (data == FRAME_CHAR_SYNC) {
                            if (recvBytes > 0) {
                                isFrameDetected = TRUE;
                                lai->recvStatus = FPS_FRAME_TRY_SYNC;
                            }
                        } else {
                            recvBuffer[recvBytes++] = data;
                        }
                    }
                }

                if (isFrameDetected) {
                    ++(lai->base.commStat.recvFrames);
                    memcpy(lai->recvBackup, recvBuffer, recvBytes);
                    lai->base.handle->OnReceived(lai->base.handle, lai->recvBackup, recvBytes, lai->sendTo);
                    recvBytes = 0;
                    isFrameDetected = FALSE;
                }
            }
            lai->recvBytes = recvBytes;
        } else {
            // 超时，检查是否需要发送
            pthread_mutex_lock(&lai->mutexSending);
            isSending = lai->isSending;
            pthread_mutex_unlock(&lai->mutexSending);

            if (isSending) {
                // 发送数据
                ssize_t written = write(lai->serial_fd, lai->sendBuffer, lai->sendBytes);
                if (written != (ssize_t)lai->sendBytes) {
                    OH_LOG_WARN(LOG_APP, "Partial write on serial port");
                }

                // 等待写入完成（简单 sleep，或使用 tcdrain）
                usleep(1000); // 1ms

                pthread_mutex_lock(&lai->mutexSending);
                lai->isSending = FALSE;
                pthread_mutex_unlock(&lai->mutexSending);

                if (lai->base.handle->OnSendQuery(lai->base.handle) > 0) {
                    lai->base.handle->OnSendRequest(lai->base.handle);
                }
            }
        }
    }

    // 关闭串口
    if (lai->serial_fd >= 0) {
        close(lai->serial_fd);
        lai->serial_fd = -1;
    }

    return nullptr;
}


/**
 * @brief 复位Lai协议状态逻辑。
 * @details 当上层协议体因为通信异常（如等待超时）需要复位Lai实体时调用。
 *  在Lai协议体通信之前不能也没有必要调用本函数。
 * @param lai 具体的Lai层协议实体。
 * @param action 复位动作，可以是以下一个或多个动作的合并（或）：
 *        - @ref LAI_TX_CLEAR
 *        - @ref LAI_RX_CLEAR 
 *        - @ref LAI_TX_ABORT 
 *        - @ref LAI_RX_ABORT 
 */
void LaiSerial_Reset(LaiSerial* lai, Uint16 action)
{
    if (action & LAI_TX_CLEAR) {
        if (lai->serial_fd >= 0) {
            tcflush(lai->serial_fd, TCOFLUSH); // 清空输出缓冲
        }
        pthread_mutex_lock(&lai->mutexSending);
        lai->isSending = FALSE;
        lai->sendBytes = 0;
        pthread_mutex_unlock(&lai->mutexSending);
    }

    if (action & LAI_RX_CLEAR) {
        if (lai->serial_fd >= 0) {
            tcflush(lai->serial_fd, TCIFLUSH); // 清空输入缓冲
        }
        lai->recvBytes = 0;
    }

    // 错误清除：POSIX 串口通常自动处理，无需显式 clearError()
}

/**
 * @brief 查询接口是否可发送数据。
 * @details 通常在 Send 之前调用。
 *  <p>可发送表示：本实体可立即发送一帧新数据，此时上层可直接调用 Send()
 *      函数把数据发送出去；
 *  <p>不可发送表示：本实体正在发送数据，或者发送缓冲中无剩余空间可供等待发送。
 *      此时上层实体应该等待 OnSendRequest 的到来进行异步发送。
 *  <p>如果正在发送，意味着发送缓冲存在数据或者硬件正在发送数据，
 *      此时上层可等待异步的发送请求。
 * @param lai 具体的Lai层协议实体，如 LaiRs485 。
 */
Bool LaiSerial_IsSendable(LaiSerial* lai)
{
    Bool status;

    pthread_mutex_lock(&lai->mutexSending);
    status = lai->isSending;
     pthread_mutex_unlock(&lai->mutexSending);   

    return (status == FALSE);
}

/**
 * @brief 发送一帧数据。
 * @details 请先调用 IsSendable() 查询发送缓冲是否足够，无剩余空间则应该等待
 *   OnSendRequest 的到来进行异步发送。
 * @param lai 具体的Lai层协议实体，如 LaiRs485 。
 * @param destAddr 本帧要发往的目标地址（链路地址）。
 * @param data 要发送的帧数据（逻辑帧的裸数据）。
 * @param len 要发送的帧长度。
 */
void LaiSerial_Send(LaiSerial* lai, Uint8 destAddr, Byte* data, int len)
{
    Byte* sendBuffer = lai->sendBuffer;
#define FIFO_SIZE       sizeof(lai->sendBuffer)
    Uint16 idxFifo = 0;          // FIFO 写指针（有效数据长度）
#define FIFO_IS_AVAIL()     (idxFifo < FIFO_SIZE)
#define FIFO_PUSH(data)     (sendBuffer[idxFifo++] = data)
#define FIFO_RESET()        (idxFifo = 0)
#define FIFO_LENTGH()       (idxFifo)
    int idxParse;
    Byte datum;

    pthread_mutex_lock(&lai->mutexSending);
    if (lai->isSending == FALSE)
    {
        // 预先转义好待发送的数据到缓冲中，真正的发送工作交给发送线程完成
        FIFO_RESET();

        // 帧起始符
        FIFO_PUSH(FRAME_CHAR_SYNC);

        // 帧业务数据
        for (idxParse = 0; idxParse < len; idxParse++)
        {
            datum = data[idxParse];
            if (datum == FRAME_CHAR_SYNC || datum == FRAME_CHAR_ESC)
            {
                FIFO_PUSH(FRAME_CHAR_ESC);
                FIFO_PUSH((datum == FRAME_CHAR_SYNC) ? FRAME_CHAR_RAW_SYNC : FRAME_CHAR_RAW_ESC);
            }
            else
            {
                FIFO_PUSH(datum);
            }
        }

        // 帧结束符
        FIFO_PUSH(FRAME_CHAR_SYNC);

        lai->sendTo = destAddr;
        lai->sendBytes = FIFO_LENTGH();
        lai->isSending = TRUE;
    }
     pthread_mutex_unlock(&lai->mutexSending);   
}


//*******************************************************************
// 实现相关


/**
 * @brief LaiSerial 协议实体初始化。
 * @param lai 具体的Lai层协议实体。
 * @param portName 要打开的串口名称。Windows 的名称形如："COM1"；Linux 的名称形如："ttyS0"。
 * @return 是否成功打开串口并初始化。
 */
Bool LaiSerial_Init(LaiSerial* lai, char* portName)
{
    memset(lai, 0, sizeof(LaiSerial));
    strncpy(lai->portName, portName, sizeof(lai->portName) - 1);
    lai->base.comm = (ILaiComm*)&s_kCommInterface;
    lai->serial_fd = -1;
    lai->mutexSending = (pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER;
    lai->isCommunicatingThreadRunning = FALSE;
    pthread_mutex_init(&lai->mutexSending, NULL);

    // 测试串口是否可打开
    int test_fd = open_serial_port(portName);
    if (test_fd >= 0) {
        close(test_fd);
        return TRUE;
    } else {
        printf("\n######### Error while open serial port %s.\n\n", portName);
        return FALSE;
    }
}


/**
 * @brief LaiSerial 协议实体结束化，释放相关资源。
 */
void LaiSerial_Uninit(LaiSerial* lai)
{
    // serial_fd 已在线程中关闭
    lai->serial_fd = -1;
    // mutex 不需要 destroy（静态初始化）
}


/**
 * @brief 开启 LaiSerial 实体服务。
 * @param lai LaiSerial 实体。
 */
void LaiSerial_Start(LaiSerial* lai)
{
    // 状态初始化
    lai->recvStatus = FPS_FRAME_TRY_SYNC;
    lai->recvEscStatus = RES_ESC_NORMAL;
    lai->recvBytes = 0;
    lai->isSending = FALSE;
    lai->sendBytes = 0;

    lai->isCommunicatingThreadRunning = TRUE;
    if (pthread_create(&lai->communicatingThread, NULL, LaiSerial_ThreadFunc, lai) != 0) {
        OH_LOG_ERROR(LOG_APP, "Failed to create serial thread");
        lai->isCommunicatingThreadRunning = FALSE;
    }
    // 不再需要 QThread::sleep(1)
}


/**
 * @brief 停止 LaiSerial 实体服务。
 * @param lai LaiSerial 实体。
 */
void LaiSerial_Stop(LaiSerial* lai)
{
    lai->isCommunicatingThreadRunning = FALSE;
    if (lai->communicatingThread) {
        pthread_join(lai->communicatingThread, NULL);
        lai->communicatingThread = 0;
    }
}

/** @} */
