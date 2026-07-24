/**
 * @file
 * @brief 同步调用器，封装了一些常用的同步命令调用操作。
 * @details 
 * @version 1.0.0
 * @author kim@erchashu.com
 * @date 2015/3/7
 */

// #include "Log.h"
#include "SyncCaller.h"
#include "AsyncTask.h"
#include "AsyncCall.h"
#include "AsyncScheduler.h"
#include "CommunicationException.h"
//#include "System/Exception.h"
#include "CommunicationPlugin/Dscp/DscpStatus.h"
// #include <QDateTime>
// #include <QDebug>
#include "hilog/log.h"
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200  // 全局domain宏，标识业务领域
#define LOG_TAG "MY_TAG"   // 全局tag宏，标识模块日志tag

using namespace std;
using namespace Communication::Dscp;
using namespace System;

namespace Communication
{

/**
 * @brief  构造同步调用器。
 * @details 默认超时时间为3000毫秒。
 *
 */

SyncCaller::SyncCaller()
{
    this->m_retries = 3;
    this->m_respond = nullptr;
    this->m_respondStatus = CallStatus::OK;
    this->m_ready = false;
    pthread_mutex_init(&m_mutex, nullptr);
    pthread_cond_init(&m_taskWaitCondition, nullptr);
    OH_LOG_INFO(LOG_APP, "SendWithStatus mutex init");
}

/**
 * @brief  构造同步调用器。
 * @details 使用指定的超时时间。
 * @param[in] timeout 超时毫秒数。
 *
 */
SyncCaller::SyncCaller(int retries)
{
    this->m_retries = retries;
    this->m_respond = nullptr;
    this->m_respondStatus = CallStatus::OK;
    this->m_ready = false;
    pthread_mutex_init(&m_mutex, nullptr);
    pthread_cond_init(&m_taskWaitCondition, nullptr);
    OH_LOG_INFO(LOG_APP, "SendWithStatus mutex init");
}

SyncCaller::~SyncCaller()
{

}

/**
 * @brief 查询同步调用的重传次数。
 * @return 重传次数。
 *
 */
int SyncCaller::GetRetries()
{
    return m_retries;
}

/**
 * @brief  设置同步调用的重传次数。
 * @param[in] retries 重传次数。
 *
 */
void SyncCaller::SetRetries(int retries)
{
    this->m_retries = retries;
}

/**
 * @brief 发送命令，并等待回应包。
 * @param[in] cmd Dscp命令。
 * @return 回应包
 *
 */
DscpRespPtr SyncCaller:: Send(DscpCmdPtr cmd)
{
    DscpRespPtr resp = nullptr;

    long timeout = this->sum(m_retries + 1) * AsyncScheduler::Instance()->GetTimeout() + 500;
    OH_LOG_INFO(LOG_APP, "Send");
    AsyncTaskPtr task(new AsyncTask(this, m_retries));
    task->AddCall(AsyncCallPtr(new AsyncCall(cmd)));
    OH_LOG_INFO(LOG_APP, "SendWithStatus AddCall");
//    m_mutex.lock();
    pthread_mutex_lock(&m_mutex);
    AsyncScheduler::Instance()->Execute(task);

//    long t1 = QDateTime::currentDateTime().toMSecsSinceEpoch();
    OH_LOG_INFO(LOG_APP, "Send ready %{public}d",m_ready);
    int t1 = 0;
    while(!m_ready)
    {
         pthread_cond_wait(&m_taskWaitCondition, &m_mutex);
    }    
   OH_LOG_INFO(LOG_APP, "SendWithStatus waitcondition");
//    if(m_taskWaitCondition.wait(&m_mutex,timeout) == true)
    {
        if (m_respondStatus == CallStatus::OK)
        {
            resp = m_respond;
            m_respond.reset();
//            m_mutex.unlock();
            pthread_mutex_unlock(&m_mutex);
        }
        else if (m_respondStatus == CallStatus::Timeout)
        {
//            logger->debug("SyncCaller Respond Timeout {addr = %s, code = %X}",
//                          cmd->addr.ToString().c_str(),
//                          cmd->code);
            OH_LOG_DEBUG(LOG_APP, "SyncCaller Respond Timeout {addr = %{public}s, code = %{public}X}",
                          cmd->addr.ToString().c_str(),
                          cmd->code);

//          m_mutex.unlock();
            pthread_mutex_unlock(&m_mutex); 
          throw CommandTimeoutException(cmd->addr,cmd->code);
        }
    }
//    else
//    {
////        long to= QDateTime::currentDateTime().toMSecsSinceEpoch() - t1;
//          int to = 0;
//
////        logger->debug("SyncCaller Wait Timeou {addr = %s, code = %X, TO = %ld ms}",
////                      cmd->addr.ToString().c_str(),
////                      cmd->code,
////                      to);
//        OH_LOG_DEBUG(LOG_APP, "SyncCaller Wait Timeou {addr = %{public}s, code = %{public}X, TO = %{public}ld ms}",
//                      cmd->addr.ToString().c_str(),
//                      cmd->code,
//                      to);
//
//        task->Deregister();
////        m_mutex.unlock();
//        pthread_mutex_unlock(&m_mutex);
//        throw CommandTimeoutException(cmd->addr,cmd->code);
//    }

    return resp;
}

/**
 * @brief  发送命令后立即返回。
 * @details 通常用于无回应的命令。
 * @param[in] cmd Dscp命令。
 *
 */
void SyncCaller::SendWithoutRespond(DscpCmdPtr cmd)
{
    OH_LOG_INFO(LOG_APP, "SendWithoutRespond");
    AsyncTaskPtr task(new AsyncTask(this, 0));
    task->AddCall(AsyncCallPtr(new AsyncCall(cmd)));
    try
    {
        AsyncScheduler::Instance()->Execute(task);
        AsyncScheduler::Instance()->Cancel(task);
    }
    catch(CommunicationException e)
    {

    }
//    catch (System::Exception e)
//    {
//    }
    catch (std::exception e)
    {
    }
}

/**
 * @brief 发送命令，并等待状态回应。
 * @return  状态回应，请参考具体命令的定义。可能的状态有：
 *  - DscpStatus::DscpInternalError  DSCP 内部错误，协议栈出错；
 *  - DscpStatus::Timeout 命令超时未返回；
 *  - DscpStatus::OK
 *  - DscpStatus::Error
 *  - DscpStatus::ErrorParam
 *  - DscpStatus::NotSupported
 *  - 其它：不同命令定义的其它返回状态。
 */
int SyncCaller::SendWithStatus(DscpCmdPtr cmd)
{
    Uint16 status = DscpStatus::Timeout;
    long timeout = this->sum(m_retries + 1) * AsyncScheduler::Instance()->GetTimeout() + 500;
    OH_LOG_INFO(LOG_APP, "SendWithStatus");
    AsyncTaskPtr task(new AsyncTask(this, m_retries));
    task->AddCall(AsyncCallPtr(new AsyncCall(cmd)));
    OH_LOG_INFO(LOG_APP, "SendWithStatus AddCall");
//    m_mutex.lock();
    pthread_mutex_lock(&m_mutex);
    AsyncScheduler::Instance()->Execute(task);
    OH_LOG_INFO(LOG_APP, "SendWithStatus Execute");

//    long t1 = QDateTime::currentDateTime().toMSecsSinceEpoch();
    OH_LOG_INFO(LOG_APP, "SendWithStatus ready %{public}d",m_ready);
    int t1 = 0;
    while(!m_ready)
    {
         pthread_cond_wait(&m_taskWaitCondition, &m_mutex);
    } 
    OH_LOG_INFO(LOG_APP, "SendWithStatus waitcondition");
//    if(m_taskWaitCondition.wait(&m_mutex,timeout))
    {
        if (m_respondStatus == CallStatus::OK)
        {
        OH_LOG_INFO(LOG_APP, "SendWithStatus OK");
            status = ((DscpStatus*)m_respond.get())->GetStatus();
//            m_mutex.unlock();
            pthread_mutex_unlock(&m_mutex);
        }
        else if (m_respondStatus == CallStatus::Timeout)
        {
//            logger->debug("SyncCaller Respond Timeout {addr = %s, code = %X}",
//                          cmd->addr.ToString().c_str(),
//                          cmd->code);
        OH_LOG_INFO(LOG_APP, "SendWithStatus Timeout");
        OH_LOG_INFO(LOG_APP, "SyncCaller Respond Timeout {addr = %{public}s, code = %{public}X}",
                          cmd->addr.ToString().c_str(),
                          cmd->code);

//          m_mutex.unlock();
            pthread_mutex_unlock(&m_mutex);
//          throw CommandTimeoutException(cmd->addr,cmd->code);
        }
    }
//    else
//    {
////        long to= QDateTime::currentDateTime().toMSecsSinceEpoch() - t1;
//        int to = 0;
////        logger->debug("SyncCaller Wait Timeou {addr = %s, code = %X, TO = %ld ms}",
////                      cmd->addr.ToString().c_str(),
////                      cmd->code,
////                      to);
//        OH_LOG_DEBUG(LOG_APP, "SyncCaller Wait Timeou {addr = %{public}s, code = %{public}X}, TO = %ld ms",
//                          cmd->addr.ToString().c_str(),
//                          cmd->code,
//                          to);
//
//        task->Deregister();
////        m_mutex.unlock();
//        pthread_mutex_unlock(&m_mutex);
//        throw CommandTimeoutException(cmd->addr,cmd->code);
//    }

    return status;
}

/**
 * @brief 任务开始时响应。
 *
 */
void SyncCaller::OnStart(AsyncTask *task)
{
    (void)task;
}


/**
 * @brief 任务中有回应到达时响应。
 * @param[in] cmd Dscp命令。
 * @return 回应包
 *
 */
bool SyncCaller::OnRespond(AsyncTask *task, AsyncCall *call, CallStatus status)
{
    (void)task;
//    m_mutex.lock();
    OH_LOG_INFO(LOG_APP, "SendWithStatus OnRespond");
    pthread_mutex_lock(&m_mutex);

    if (status == CallStatus::OK)
    {
        m_respondStatus = CallStatus::OK;
        this->m_respond = call->GetRespond();
        m_ready = true;
//        m_taskWaitCondition.wakeAll();
        pthread_cond_signal(&m_taskWaitCondition);      // 唤醒等待者
        OH_LOG_INFO(LOG_APP, "SendWithStatus OnRespond Wakeup Ok");
    }
    else if (status == CallStatus::Timeout)
    {
        m_respondStatus = CallStatus::Timeout;
        m_ready = true;
//        m_taskWaitCondition.wakeAll();
        pthread_cond_signal(&m_taskWaitCondition);      // 唤醒等待者
        OH_LOG_INFO(LOG_APP, "SendWithStatus OnRespond Wakeup timeout");
    }
    else
    {
//        logger->debug("no OnRespond Status type");
        OH_LOG_DEBUG(LOG_APP, "no OnRespond Status type");
    }

//    m_mutex.unlock();
    pthread_mutex_unlock(&m_mutex);

    return true;
}

/**
 * @brief 任务结束（所有异步调用均已完成）时响应。
 *
 */
void SyncCaller::OnStop(AsyncTask *task, CallStatus status)
{
     (void)task;
     (void)status;
}

int SyncCaller::sum(int n)
{
    int sum = 0;

    for(int i = 0; i <= n; i++)
    {
        sum += i;
    }

    return sum;
}

}
