/**
 * @file
 * @brief 事件处理器。
 * @details
 * @version 1.0.0
 * @author kim@erchashu.com
 * @date 2015/3/7
 */


#ifndef COMMUNICATION_EVENTHANDLER_H
#define COMMUNICATION_EVENTHANDLER_H

#include <list>
//#include "Log.h"
//#include "LuipShare.h"
#include "Stack/IDscpReceivable.h"
#include "IEventReceivable.h"
#include "IEventReceivable.h"
#include "Stack/DncpStack.h"
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

using std::list;
using Communication::Stack::IDscpReceivable;
using Communication::Stack::DncpStack;

namespace Communication
{

/**
 * @brief 事件处理器。Singleton 类。
 * @details 处理下位机主动上报的某个事件。。
 *
 */
class ExpectInfo
{

public:

    DscpAddress addr;
    int code;
    int timeout;
    pthread_cond_t* waitCondition;
    DscpEventPtr event;
};

/**
 * @brief 事件注册信息。Singleton 类。
 * @details 上层需要处理下位上报的事件的注册信息。
 *
 */
class RegisterInfo
{

public:

    DscpAddress addr;
    int code;
    IEventReceivable* handle;
};


/**
 * @brief DSCP事件处理器。Singleton 类。
 * @details 为上层应用接口提供一致的事件处理方式：事件同步等待和异步通知。
 *
 */
class EventHandler : public IDscpReceivable
{
public:
    static EventHandler* Instance();

    void Init();
    void Uninit();
    DscpEventPtr GetEvent(DscpAddress addr, int code);
    void EmptyEvents();
    DscpEventPtr Expect(DscpAddress addr, int code, int timeout);
    void Register(DscpAddress addr, int code, IEventReceivable* handle);
    void Deregister(DscpAddress addr, int code, IEventReceivable* handle);
    void OnReceive(DscpPackPtr pack);

    ~EventHandler();

protected:
//    void run();
    // 真正的线程工作逻辑（普通成员函数）
    void EventHandler_ThreadFunc();  

private:
    bool ExpectEventMatch(DscpEventPtr event);
    bool RegisterEventMatch(DscpEventPtr event);
    void SaveRemainEvent(DscpEventPtr event);
// 静态入口函数（符合 pthread_create 要求）
    static void* ThreadEntry(void* arg);  
private:
    std::list<ExpectInfo> m_expectList;
    std::list<RegisterInfo> m_registerList;
    std::list<DscpEventPtr> m_remainEventList;
    std::list<DscpEventPtr> m_DscpEventList;

    pthread_mutex_t m_expectMutex;
    pthread_mutex_t m_registerMutex;
    pthread_mutex_t m_remainMutex;
    pthread_mutex_t DscpEventMutex;

    bool m_isPrint;

    static  std::unique_ptr<EventHandler> m_instance;
};

}

#endif  //COMMUNICATION_EVENTHANDLER_H
