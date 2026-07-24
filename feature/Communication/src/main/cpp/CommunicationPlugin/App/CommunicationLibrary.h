#ifndef COMMUNICATION_H
#define COMMUNICATION_H

#include <memory>
//#include "Log.h"
#include "/CommunicationPlugin/Common/Types.h"
#include "CommunicationPlugin/Stack/DncpMcStack.h"
//#include "LuipShare.h"

using System::String;
class IConnectStatusNotifiable;

namespace Communication
{
class CommunicationLibrary
{

public:
    ~CommunicationLibrary();
    static CommunicationLibrary* Instance();
    bool Init();
    void Uninit();
    void Proxy();
    void AddSlaveNode(int addr);
    void SetDncpMcStackCmdTable(DscpCmdTable cmdTable, DscpVersion version);
    bool InitDncpStack(char* serialPort, bool bridgeMode,
              const char* bridgeIP, IConnectStatusNotifiable *handle);
    String GetVersion();

private:
    static std::unique_ptr<CommunicationLibrary> m_instance;
};
}
#endif // COMMUNICATION_H
