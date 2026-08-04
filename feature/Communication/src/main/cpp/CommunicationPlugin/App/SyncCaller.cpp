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
#include <asm-generic/errno.h>
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
    pthread_mutex_init(&m_mutex, nullptr);
    pthread_cond_init(&m_taskWaitCondition, nullptr);
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
    pthread_mutex_init(&m_mutex, nullptr);
    pthread_cond_init(&m_taskWaitCondition, nullptr);
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
    OH_LOG_DEBUG(LOG_APP, "Send");
    AsyncTaskPtr task(new AsyncTask(this, m_retries));
    task->AddCall(AsyncCallPtr(new AsyncCall(cmd)));
    OH_LOG_DEBUG(LOG_APP, "SendWithStatus AddCall");
    pthread_mutex_lock(&m_mutex);
    AsyncScheduler::Instance()->Execute(task);

    struct timespec absTimeout;
    clock_gettime(CLOCK_REALTIME, &absTimeout);
    absTimeout.tv_sec += timeout / 1000;
    absTimeout.tv_nsec += (timeout % 1000) * 1000000L;
    if (absTimeout.tv_nsec >= 1000000000L) {
        absTimeout.tv_sec += 1;
        absTimeout.tv_nsec -= 1000000000L;
    }
    
    // timedwait 本身就会在被 signal 唤醒后立即返回（返回值为0）
    // 超时则返回 ETIMEDOUT（非0）
    int waitResult = pthread_cond_timedwait(&m_taskWaitCondition, &m_mutex, &absTimeout); 
    
   OH_LOG_INFO(LOG_APP, "SendWithStatus waitcondition");
    if(waitResult != ETIMEDOUT)
    {
        if (m_respondStatus == CallStatus::OK)
        {
            resp = m_respond;
            m_respond.reset();
            pthread_mutex_unlock(&m_mutex);
        }
        else if (m_respondStatus == CallStatus::Timeout)
        {
            OH_LOG_DEBUG(LOG_APP, "SyncCaller Respond Timeout {addr = %{public}s, code = %{public}X}",
                          cmd->addr.ToString().c_str(),
                          cmd->code);
            pthread_mutex_unlock(&m_mutex); 
            throw CommandTimeoutException(cmd->addr,cmd->code);
        }
    }
    else
    {
        int to = (long long)absTimeout.tv_sec * 1000 
                   + absTimeout.tv_nsec / 1000000;
        OH_LOG_DEBUG(LOG_APP, "SyncCaller Wait Timeou {addr = %{public}s, code = %{public}X, TO = %{public}ld ms}",
                      cmd->addr.ToString().c_str(),
                      cmd->code,
                      to);

        task->Deregister();
        pthread_mutex_unlock(&m_mutex);
        throw CommandTimeoutException(cmd->addr,cmd->code);
    }

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
    AsyncTaskPtr task(new AsyncTask(this, m_retries));
    task->AddCall(AsyncCallPtr(new AsyncCall(cmd)));
    pthread_mutex_lock(&m_mutex);
    AsyncScheduler::Instance()->Execute(task);

    struct timespec absTimeout;
    clock_gettime(CLOCK_REALTIME, &absTimeout);
    absTimeout.tv_sec += timeout / 1000;
    absTimeout.tv_nsec += (timeout % 1000) * 1000000L;
    if (absTimeout.tv_nsec >= 1000000000L) {
        absTimeout.tv_sec += 1;
        absTimeout.tv_nsec -= 1000000000L;
    }
    
    // timedwait 本身就会在被 signal 唤醒后立即返回（返回值为0）
    // 超时则返回 ETIMEDOUT（非0）
    int waitResult = pthread_cond_timedwait(&m_taskWaitCondition, &m_mutex, &absTimeout);
    
    if(waitResult != ETIMEDOUT)
    {
        if (m_respondStatus == CallStatus::OK)
        {
            status = ((DscpStatus*)m_respond.get())->GetStatus();
            pthread_mutex_unlock(&m_mutex);
        }
        else if (m_respondStatus == CallStatus::Timeout)
        {
            OH_LOG_INFO(LOG_APP, "SendWithStatus Timeout");
            OH_LOG_INFO(LOG_APP, "SyncCaller Respond Timeout {addr = %{public}s, code = %{public}X}",
                              cmd->addr.ToString().c_str(),
                              cmd->code);
            pthread_mutex_unlock(&m_mutex);
            throw CommandTimeoutException(cmd->addr,cmd->code);
        }
    }
    else
    {
        int to = (long long)absTimeout.tv_sec * 1000 
                   + absTimeout.tv_nsec / 1000000;
        OH_LOG_ERROR(LOG_APP, "SyncCaller Wait Timeou {addr = %{public}s, code = %{public}X}, TO = %ld ms",
                          cmd->addr.ToString().c_str(),
                          cmd->code,
                          to);
        task->Deregister();
        pthread_mutex_unlock(&m_mutex);
        throw CommandTimeoutException(cmd->addr,cmd->code);
    }

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
    OH_LOG_DEBUG(LOG_APP, "SendWithStatus OnRespond");
    pthread_mutex_lock(&m_mutex);

    if (status == CallStatus::OK)
    {
        m_respondStatus = CallStatus::OK;
        this->m_respond = call->GetRespond();
        pthread_cond_signal(&m_taskWaitCondition);      // 唤醒等待者
        OH_LOG_DEBUG(LOG_APP, "SendWithStatus OnRespond Wakeup Ok");
    }
    else if (status == CallStatus::Timeout)
    {
        m_respondStatus = CallStatus::Timeout;
        pthread_cond_signal(&m_taskWaitCondition);      // 唤醒等待者
        OH_LOG_INFO(LOG_APP, "SendWithStatus OnRespond Wakeup timeout");
    }
    else
    {
        OH_LOG_DEBUG(LOG_APP, "no OnRespond Status type");
    }

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
