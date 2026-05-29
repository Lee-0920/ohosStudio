/**
 * @file
 * @brief 事件处理器。
 * @details
 * @version 1.0.0
 * @author kim@erchashu.com
 * @date 2015/3/7
 */

// #include "Log.h"
#include "CommunicationException.h"
#include "EventHandler.h"
//#include "LuaEngine/LuaEngine.h"
//#include "Lua/App.h"
// #include <QDebug>


using namespace std;
using namespace Communication::Stack;
using namespace Communication::Dscp;
//using namespace OOLUA;
//using namespace Lua;

static bool ready = false;

namespace Communication
{

unique_ptr<EventHandler> EventHandler::m_instance(nullptr);

//static int expectCnt = 0;

/**
 * @brief @brief 获取全局唯一的 EventHandler 对象（单件）。
 * @details
 * @param[in]
 * @return  EventHandler 对象。
 *
 */
EventHandler *EventHandler::Instance()
{
    if (!m_instance)
    {
        m_instance.reset(new EventHandler);
    }

    return m_instance.get();
}

// 静态入口函数：作为 pthread_create 的回调
void* EventHandler::ThreadEntry(void* arg) {
    if (arg == nullptr) return nullptr;

    EventHandler* handler = static_cast<EventHandler*>(arg);
    handler->EventHandler_ThreadFunc();  // 调用真正的成员函数
    return nullptr;
}

/**
 * @brief 事件处理初始化。
 * @details 向DncpStack注册事件处理器。
 *
 */
void EventHandler::Init()
{
    //获取仪器是否处于开发者模式
    m_isPrint = false;
//    LuaEngine* luaEngine = LuaEngine::Instance();
//    lua_State* state = luaEngine->GetThreadState();
//    luaEngine->GetLuaValue(state, "config.system.debugMode", m_isPrint);

    DncpStack::Instance()->SetEventHandler(this);
    pthread_mutex_init(&m_expectMutex,NULL);
    pthread_mutex_init(&m_registerMutex,NULL);
    pthread_mutex_init(&m_remainMutex,NULL);
    pthread_mutex_init(&DscpEventMutex,NULL);

    pthread_t tid;
    // 把 this 作为参数传给静态入口函数
    if (pthread_create(&tid, NULL, &EventHandler::ThreadEntry, this) != 0) {
        OH_LOG_ERROR(LOG_APP, "Failed to create EventHandler thread");
    } else {
        OH_LOG_DEBUG(LOG_APP, "EventHandler thread created successfully");
        // 可选：保存 tid 用于后续 join 或 detach
    }
}

/**
 * @brief 取消事件处理。
 * @details 在DncpStack注销事件处理器。
 *
 */
void EventHandler::Uninit()
{
    DncpStack::Instance()->SetEventHandler(NULL);
    m_expectList.clear();
    m_registerList.clear();
    m_remainEventList.clear();
}

/**
 * @brief 从列表中取出符合条件的事件。
 * @details 一次只能取出一条符合的事件，如果有多条，需要重复调用，直到返回NULL。
 * @param[in] addr 下位机节点地址。
 * @param[in] code 事件类型代码。
 * @return
 *
 */
DscpEventPtr EventHandler::GetEvent(Dscp::DscpAddress addr, int code)
{
    DscpEventPtr event = nullptr;

    if (!m_remainEventList.empty())
    {
//        m_remainMutex.lock();
        pthread_mutex_lock(&m_remainMutex);
        for(std::list<DscpEventPtr>::iterator it = m_remainEventList.begin(); it != m_remainEventList.end();it++)
        {
            if ((*it)->addr.a1 == addr.a1 && (*it)->addr.a2 == addr.a2 &&
                (*it)->addr.a3 == addr.a3 && (*it)->addr.a4 == addr.a4 &&
                (*it)->code == code)
            {
                event = (*it);
                m_remainEventList.erase(it);
//                logger->debug("m_remainEvents-- = %d, %s",
//                              m_remainEventList.size(),
//                              event->ToString().c_str());
                OH_LOG_DEBUG(LOG_APP, "m_remainEvents-- = %{public}d, %{public}s",
                              m_remainEventList.size(),
                              event->ToString().c_str());
                break;
            }
        }

//        m_remainMutex.unlock();
        pthread_mutex_unlock(&m_remainMutex);
    }
    return event;
}

/**
 * @brief 清空所有接收列表事件。
 *
 */
void EventHandler::EmptyEvents()
{
//    m_remainMutex.lock();
    pthread_mutex_lock(&m_remainMutex);
    m_remainEventList.clear();
//    m_remainMutex.unlock();
    pthread_mutex_unlock(&m_remainMutex);
}


/**
 * @brief 同步等待指定事件。
 * @details 调用时，如果剩余事件列表中已经有符合条件的事件，则直接取出返回，
 * @details 否则阻塞等待，直到事件到达或超时。超时将抛出 TimeoutException 异常。
 * @param[in] addr 下位机节点地址。
 * @param[in] code 事件类型代码。
 * @param[in] Timeout 等待超时。
 * @return
 *
 */
DscpEventPtr EventHandler::Expect(Dscp::DscpAddress addr, int code, int timeout)
{
   DscpEventPtr event = nullptr;

   // 如果剩余事件列表中已经有符合条件的事件，则直接取出返回
   event = GetEvent(addr, code);

   // 阻塞等待，直到事件到达或超时
   if (event == nullptr)
   {
//        QMutex mutex;
//        QWaitCondition* waitCondition = new QWaitCondition();
        pthread_mutex_t mutex;
        pthread_mutex_init(&mutex, NULL);
        pthread_cond_t* waitCondition;
        pthread_cond_init(waitCondition, NULL);

        ExpectInfo expectInfo;
        expectInfo.addr = addr;
        expectInfo.code = code;
        expectInfo.timeout = timeout;
        expectInfo.waitCondition = waitCondition;

//        m_expectMutex.lock();
        pthread_mutex_lock(&m_expectMutex);
        m_expectList.push_back(expectInfo);
//        m_expectMutex.unlock();
        pthread_mutex_unlock(&m_expectMutex);

//        mutex.lock();
        pthread_mutex_lock(&mutex);
        while(ready)
        {
            pthread_cond_wait(waitCondition, &mutex);
        }
//        if(waitCondition->wait(&mutex,timeout) == true)
        {
//            m_expectMutex.lock();
            pthread_mutex_lock(&m_expectMutex);
            for(std::list<ExpectInfo>::iterator it = m_expectList.begin(); it != m_expectList.end();it++)
            {
                if ((*it).addr.a1 == expectInfo.addr.a1 && (*it).addr.a2 == expectInfo.addr.a2 &&
                    (*it).addr.a3 == expectInfo.addr.a3 && (*it).addr.a4 == expectInfo.addr.a4 &&
                    (*it).code == expectInfo.code)
                {
                    event = (*it).event;
                    m_expectList.erase(it);
                    break;
                }
            }
//            m_expectMutex.unlock();
            pthread_mutex_unlock(&m_expectMutex);

//            mutex.unlock();
            pthread_mutex_unlock(&mutex);

            if (waitCondition)
            {
                delete waitCondition;
            }
        }
//        else
//        {
//            m_expectMutex.lock();
//            for(std::list<ExpectInfo>::iterator it = m_expectList.begin(); it != m_expectList.end();it++)
//            {
//                if ((*it).addr.a1 == expectInfo.addr.a1 && (*it).addr.a2 == expectInfo.addr.a2 &&
//                    (*it).addr.a3 == expectInfo.addr.a3 && (*it).addr.a4 == expectInfo.addr.a4 &&
//                    (*it).code == expectInfo.code)
//                {
//                    m_expectList.erase(it);
//                    break;
//                }
//            }
//            m_expectMutex.unlock();
//
//            mutex.unlock();
//
//            if (waitCondition)
//            {
//                delete waitCondition;
//            }
//            event = GetEvent(addr, code);
//            if (event ==nullptr)
//                throw ExpectEventTimeoutException(addr, code);
//        }
   }

   return event;
}

/**
 * @brief  上层注册感兴趣的事件。
 * @details 当符合条件的事件到达时，通过 IEventReceivable  接口通知客户代码。
 * @param[in] addr 下位机节点地址。
 * @param[in] code 事件类型代码。
 * @param[in] handle 接收事件通知句柄。
 */
void EventHandler::Register(Dscp::DscpAddress addr, int code, IEventReceivable *handle)
{
    RegisterInfo registerInfo;
    registerInfo.addr = addr;
    registerInfo.code = code;
    registerInfo.handle = handle;

//    m_registerMutex.lock();
    pthread_mutex_lock(&m_registerMutex);
    m_registerList.push_back(registerInfo);
//    m_registerMutex.unlock();
    pthread_mutex_unlock(&m_registerMutex);
}

/**
 * @brief  撤消注册指定的事件。
 * @details 撤消后，将不监听该事件。
 * @param[in] addr 下位机节点地址。
 * @param[in] code 事件类型代码。
 * @param[in] handle 接收事件通知句柄。
 */
void EventHandler::Deregister(Dscp::DscpAddress addr, int code, IEventReceivable* handle)
{
//    m_registerMutex.lock();
    pthread_mutex_lock(&m_registerMutex);
    for(std::list<RegisterInfo>::iterator it = m_registerList.begin(); it != m_registerList.end();it++)
    {
        if ((*it).addr.a1 == addr.a1 && (*it).addr.a2 == addr.a2 &&
            (*it).addr.a3 == addr.a3 && (*it).addr.a4 == addr.a4 &&
            (*it).code == code && (*it).handle == handle)
        {
            m_registerList.erase(it);
            break;
        }
    }
//    m_registerMutex.unlock();
    pthread_mutex_unlock(&m_registerMutex);
}

/**
 * @brief  事件处理器接收触发事件的数据包。
 * @param[in] pack 触发事件的数据包
 *
 */
void EventHandler::OnReceive(DscpPackPtr pack)
{
    DscpEventPtr event = dynamic_pointer_cast<DscpEvent>(pack);

    if (!ExpectEventMatch(event))
    {
//        DscpEventMutex.lock();
        pthread_mutex_lock(&DscpEventMutex);
        m_DscpEventList.push_back(event);
//        DscpEventMutex.unlock();
        pthread_mutex_unlock(&DscpEventMutex);
    }
}

EventHandler::~EventHandler()
{

}

// 线程入口函数
void EventHandler::EventHandler_ThreadFunc(void) 
{
//    logger->debug("EventHandler thread ID = %d", QThread::currentThreadId());
    // 获取线程 ID（用于日志）
    pid_t tid = syscall(SYS_gettid);
    OH_LOG_DEBUG(LOG_APP, "LaiSerial Thread ID = %{public}d", (int)tid);
    while (true)
    {
        if(!m_DscpEventList.empty())
        {
//            DscpEventMutex.lock();
            pthread_mutex_lock(&DscpEventMutex);
            DscpEventPtr event = m_DscpEventList.front();
            m_DscpEventList.pop_front();
//            DscpEventMutex.unlock();
            pthread_mutex_unlock(&DscpEventMutex);

            // 注册事件触发
            if (!RegisterEventMatch(event))
            {
                SaveRemainEvent(event);   // 除上层注册和期望事件之外，下位机主动触发的事件
            }
        }

       usleep(50*1000);
    }
}

// 期望事件匹配
bool EventHandler::ExpectEventMatch(DscpEventPtr event)
{
    bool status = false;

    if (!m_expectList.empty())
    {
//        m_expectMutex.lock();
        pthread_mutex_lock(&m_expectMutex);
        for(std::list<ExpectInfo>::iterator it = m_expectList.begin(); it != m_expectList.end();it++)
        {
            if ((*it).addr.a1 == event->addr.a1 && (*it).addr.a2 == event->addr.a2 &&
                (*it).addr.a3 == event->addr.a3 && (*it).addr.a4 == event->addr.a4 &&
                (*it).code == event->code)
            {
                (*it).event = event;
                ready = true;
//                (*it).waitCondition->wakeOne();
                pthread_cond_signal((*it).waitCondition);   

                //限值日志打印  开发者模式下才打印事件回包
                if (m_isPrint)
                {
//                    logger->debug(event->ToString());
                    OH_LOG_DEBUG(LOG_APP, "%{public}s", event->ToString().c_str());
                }

                status = true;
                break;
            }
        }
//        m_expectMutex.unlock();
        pthread_mutex_unlock(&m_expectMutex);
    }
    return status;
}

// 注册事件匹配
bool EventHandler::RegisterEventMatch(DscpEventPtr event)
{
    bool status = false;
    if (!m_registerList.empty())
    {
//        m_registerMutex.lock();
        pthread_mutex_lock(&m_registerMutex);
        for(std::list<RegisterInfo>::iterator it = m_registerList.begin(); it != m_registerList.end();it++)
        {
            if ((*it).addr.a1 == event->addr.a1 && (*it).addr.a2 == event->addr.a2 &&
                (*it).addr.a3 == event->addr.a3 && (*it).addr.a4 == event->addr.a4 &&
                (*it).code == event->code)
            {
                (*it).handle->OnReceive(event);
                status = true;
                break;
            }
        }
//        m_registerMutex.unlock();
        pthread_mutex_unlock(&m_registerMutex);
    }
    return status;
}

// 下位机主动触发的事件匹配
void EventHandler::SaveRemainEvent(DscpEventPtr event)
{
//    m_remainMutex.lock();
    pthread_mutex_lock(&m_remainMutex);
    if (m_remainEventList.size() == 100)
    {
        m_remainEventList.pop_back();
        m_remainEventList.push_front(event);
    }
    else
    {
        m_remainEventList.push_front(event);

//        logger->debug("m_remainEvents++ = %d, %s",
//                      m_remainEventList.size(),
//                      event->ToString().c_str());
        OH_LOG_DEBUG(LOG_APP, "m_remainEvents++ = %{public}d, %{public}s",
                      m_remainEventList.size(),
                      event->ToString().c_str());
    }

//    m_remainMutex.unlock();
    pthread_mutex_unlock(&m_remainMutex);
}

}
